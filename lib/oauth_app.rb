# frozen_string_literal: true

require "sinatra/base"
require "faraday"
require "json"

class OAuthApp < Sinatra::Base
  AUTHORIZE_URL = "https://launchpad.37signals.com/authorization/new"
  TOKEN_URL = "https://launchpad.37signals.com/authorization/token"

  get "/authorize" do
    unless oauth_mode?
      halt 404, "OAuth not configured"
    end

    redirect "#{AUTHORIZE_URL}?type=web_server" \
             "&client_id=#{ENV["BASECAMP_CLIENT_ID"]}" \
             "&redirect_uri=#{Rack::Utils.escape(ENV["BASECAMP_REDIRECT_URI"])}"
  end

  get "/callback" do
    code = params["code"]

    unless code && !code.empty?
      halt 400, error_page("Missing authorization code")
    end

    response = Faraday.post(TOKEN_URL) do |req|
      req.headers["Content-Type"] = "application/json"
      req.body = JSON.generate(
        type: "web_server",
        client_id: ENV["BASECAMP_CLIENT_ID"],
        client_secret: ENV["BASECAMP_CLIENT_SECRET"],
        redirect_uri: ENV["BASECAMP_REDIRECT_URI"],
        code: code
      )
    end

    unless response.success?
      halt response.status, error_page("Token exchange failed: #{response.body}")
    end

    token_data = JSON.parse(response.body)

    TOKEN_STORE.update!(
      access_token: token_data["access_token"],
      refresh_token: token_data["refresh_token"],
      expires_in: token_data["expires_in"]
    )

    BASECAMP_CLIENT.invalidate_connection!

    content_type :html
    success_page
  end

  private

  def oauth_mode?
    ENV["BASECAMP_CLIENT_ID"] && !ENV["BASECAMP_CLIENT_ID"].empty? &&
      ENV["BASECAMP_CLIENT_SECRET"] && !ENV["BASECAMP_CLIENT_SECRET"].empty?
  end

  def success_page
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title>Authorization Successful</title></head>
      <body>
        <h1>Authorization successful!</h1>
        <p>You can close this window.</p>
      </body>
      </html>
    HTML
  end

  def error_page(message)
    content_type :html
    <<~HTML
      <!DOCTYPE html>
      <html>
      <head><title>Authorization Failed</title></head>
      <body>
        <h1>Authorization failed</h1>
        <p>#{Rack::Utils.escape_html(message)}</p>
      </body>
      </html>
    HTML
  end
end
