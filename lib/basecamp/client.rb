# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"

module Basecamp
  class Client
    BASE_URL = "https://3.basecampapi.com"

    def initialize(access_token:, account_id:)
      @access_token = access_token
      @account_id = account_id
    end

    def get(path)
      response = connection.get(path)
      handle_response(response)
    end

    def post(path, body = {})
      response = connection.post(path) do |req|
        req.body = JSON.generate(body)
      end
      handle_response(response)
    end

    def put(path, body = {})
      response = connection.put(path) do |req|
        req.body = JSON.generate(body)
      end
      handle_response(response)
    end

    private

    def connection
      @connection ||= Faraday.new(url: "#{BASE_URL}/#{@account_id}") do |f|
        f.request :retry, {
          max: 3,
          interval: 1,
          backoff_factor: 2,
          retry_statuses: [429, 503],
          retry_if: ->(_env, _exception) { false },
          retry_block: ->(env, _opts, _retries, _exception) {
            retry_after = env.response_headers["Retry-After"]
            sleep(retry_after.to_i) if retry_after
          }
        }
        f.headers["Authorization"] = "Bearer #{@access_token}"
        f.headers["Content-Type"] = "application/json"
        f.headers["User-Agent"] = "BasecampMCP (https://github.com/basecamp-mcp)"
        f.adapter Faraday.default_adapter
      end
    end

    def handle_response(response)
      case response.status
      when 200..299
        return nil if response.body.nil? || response.body.empty?
        JSON.parse(response.body)
      when 401
        raise AuthenticationError, "Invalid or expired access token"
      when 404
        raise NotFoundError, "Resource not found"
      when 429
        raise RateLimitError, "Rate limit exceeded"
      else
        raise ApiError.new(
          "Basecamp API error: #{response.status} - #{response.body}",
          status: response.status
        )
      end
    end
  end
end
