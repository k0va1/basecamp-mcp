require "faraday"
require "json"

module Basecamp
  class OAuthRefresher
    TOKEN_URL = "https://launchpad.37signals.com/authorization/token"

    def initialize(client_id:, client_secret:, token_store:)
      @client_id = client_id
      @client_secret = client_secret
      @token_store = token_store
    end

    def refresh!
      response = Faraday.post(TOKEN_URL) do |req|
        req.params["type"] = "refresh"
        req.body = {
          client_id: @client_id,
          client_secret: @client_secret,
          refresh_token: @token_store.refresh_token
        }
      end

      unless response.status == 200
        raise AuthenticationError, "OAuth token refresh failed (#{response.status}): #{response.body}"
      end

      data = JSON.parse(response.body)
      @token_store.update!(
        access_token: data.fetch("access_token"),
        refresh_token: data.fetch("refresh_token", @token_store.refresh_token),
        expires_in: data.fetch("expires_in", 1_209_600)
      )

      @token_store.access_token
    end
  end
end
