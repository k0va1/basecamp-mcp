require "json"
require "fileutils"

module Basecamp
  class TokenStore
    DEFAULT_PATH = ".basecamp_tokens.json"

    attr_reader :token_file_path

    def initialize(token_file_path: DEFAULT_PATH)
      @token_file_path = token_file_path
      @mutex = Mutex.new
      @data = load_from_file
    end

    def access_token
      @mutex.synchronize { @data["access_token"] }
    end

    def refresh_token
      @mutex.synchronize { @data["refresh_token"] }
    end

    def expires_at
      @mutex.synchronize do
        @data["expires_at"] ? Time.at(@data["expires_at"]) : nil
      end
    end

    def expired?
      @mutex.synchronize do
        return true unless @data["expires_at"]
        Time.now.to_f >= @data["expires_at"]
      end
    end

    def expires_soon?(margin_seconds = 300)
      @mutex.synchronize do
        return true unless @data["expires_at"]
        Time.now.to_f >= @data["expires_at"] - margin_seconds
      end
    end

    def update!(access_token:, refresh_token:, expires_in:)
      @mutex.synchronize do
        @data["access_token"] = access_token
        @data["refresh_token"] = refresh_token
        @data["expires_at"] = Time.now.to_f + expires_in.to_i
        save_to_file
      end
    end

    def seed!(access_token:, expires_in: 1_209_600)
      return if File.exist?(@token_file_path)

      update!(access_token: access_token, refresh_token: nil, expires_in: expires_in)
    end

    private

    def load_from_file
      return {} unless File.exist?(@token_file_path)

      JSON.parse(File.read(@token_file_path))
    rescue JSON::ParserError
      {}
    end

    def save_to_file
      File.write(@token_file_path, JSON.pretty_generate(@data))
    end
  end
end
