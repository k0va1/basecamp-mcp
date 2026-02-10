# frozen_string_literal: true

ENV["BASECAMP_ACCESS_TOKEN"] ||= "test-token"
ENV["BASECAMP_ACCOUNT_ID"] ||= "12345"

require_relative "../app"
require "minitest/autorun"
require "webmock/minitest"

WebMock.disable_net_connect!
