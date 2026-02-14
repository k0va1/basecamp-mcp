# frozen_string_literal: true

require "faraday"
require "faraday/retry"
require "json"
require "logger"

module Basecamp
  class Client
    BASE_URL = "https://3.basecampapi.com"

    def initialize(access_token:, account_id:, token_store: nil, refresher: nil)
      @access_token = access_token
      @account_id = account_id
      @token_store = token_store
      @refresher = refresher
    end

    def get(path)
      with_token_refresh do
        response = connection.get(path)
        handle_response(response)
      end
    end

    def post(path, body = {})
      with_token_refresh do
        response = connection.post(path) do |req|
          req.body = JSON.generate(body)
        end
        handle_response(response)
      end
    end

    def put(path, body = {})
      with_token_refresh do
        response = connection.put(path) do |req|
          req.body = JSON.generate(body)
        end
        handle_response(response)
      end
    end

    def invalidate_connection!
      invalidate_connection
    end

    private

    def with_token_refresh(&block)
      if refreshable?
        proactive_refresh if @token_store.expires_soon?
        begin
          block.call
        rescue AuthenticationError
          reactive_refresh
          block.call
        end
      else
        block.call
      end
    end

    def refreshable?
      @token_store && @refresher
    end

    def proactive_refresh
      @refresher.refresh!
      invalidate_connection
    end

    def reactive_refresh
      @refresher.refresh!
      invalidate_connection
    end

    def invalidate_connection
      @access_token = @token_store.access_token
      @connection = nil
    end

    def connection
      @connection ||= Faraday.new(url: "#{BASE_URL}/#{@account_id}/") do |f|
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
        f.response :logger, Logger.new($stdout), bodies: true if ENV["DEBUG"]
        f.headers["Authorization"] = "Bearer #{@access_token}"
        f.headers["Content-Type"] = "application/json"
        f.headers["User-Agent"] = "BasecampMCP (https://github.com/k0va1/basecamp-mcp)"
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
