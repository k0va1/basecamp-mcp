# frozen_string_literal: true

require "sinatra/base"
require_relative "app"

class HealthApp < Sinatra::Base
  get "/" do
    content_type :json
    {status: "ok"}.to_json
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
    use DowncaseHeaders
    run mcp_app
  end
end

run app
