# frozen_string_literal: true

require "sinatra/base"
require_relative "app"

class HealthApp < Sinatra::Base
  get "/" do
    content_type :json
    {status: "ok"}.to_json
  end
end

# Validates Bearer token on incoming requests when MCP_AUTH_TOKEN is set.
# Returns 401 if the token is missing or incorrect.
class TokenAuth
  def initialize(app, token:)
    @app = app
    @token = token
  end

  def call(env)
    return @app.call(env) unless @token

    auth = env["HTTP_AUTHORIZATION"]
    if auth&.start_with?("Bearer ") && Rack::Utils.secure_compare(auth.delete_prefix("Bearer "), @token)
      @app.call(env)
    else
      [401, {"content-type" => "application/json"}, ['{"error":"Unauthorized"}']]
    end
  end
end

# Rack 3 requires lowercase header names, but the MCP transport
# may return mixed-case headers. This middleware normalizes them.
class DowncaseHeaders
  def initialize(app)
    @app = app
  end

  def call(env)
    status, headers, body = @app.call(env)
    normalized = headers.each_with_object({}) { |(k, v), h| h[k.downcase] = v }
    [status, normalized, body]
  end
end

mcp_transport = TRANSPORT

mcp_app = lambda do |env|
  request = Rack::Request.new(env)
  mcp_transport.handle_request(request)
end

app = Rack::Builder.new do
  map "/health" do
    run HealthApp
  end

  map "/" do
    use TokenAuth, token: ENV["MCP_AUTH_TOKEN"]
    use DowncaseHeaders
    run mcp_app
  end
end

run app
