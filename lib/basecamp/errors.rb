# frozen_string_literal: true

module Basecamp
  class Error < StandardError; end

  class AuthenticationError < Error; end

  class NotFoundError < Error; end

  class RateLimitError < Error; end

  class ApiError < Error
    attr_reader :status

    def initialize(message, status: nil)
      @status = status
      super(message)
    end
  end
end
