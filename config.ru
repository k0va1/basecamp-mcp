require "sinatra/base"
require_relative "app"

class HealthApp < Sinatra::Base
  set :host_authorization, permitted: :any

  get "/" do
    content_type :json
    {status: "ok"}.to_json
  end
end

require_relative "lib/middleware/token_auth"
require_relative "lib/middleware/downcase_headers"
require_relative "lib/middleware/request_logger"

mcp_transport = TRANSPORT

mcp_app = lambda do |env|
  request = Rack::Request.new(env)
  mcp_transport.handle_request(request)
end

app = Rack::Builder.new do
  map "/health" do
    run HealthApp
  end

  map "/oauth" do
    run OAuthApp
  end

  map "/" do
    use RequestLogger if ENV["DEBUG"]
    use TokenAuth, token: ENV["MCP_AUTH_TOKEN"]
    use DowncaseHeaders
    run mcp_app
  end
end

run app
