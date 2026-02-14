require "dotenv/load"
require "mcp"

require_relative "lib/basecamp/errors"
require_relative "lib/basecamp/client"
require_relative "lib/basecamp/token_store"
require_relative "lib/basecamp/oauth_refresher"
require_relative "lib/oauth_app"
require_relative "lib/tools/base_tool"
Dir[File.join(__dir__, "lib/tools", "*.rb")].each { |f| require f }

TOOLS = Tools::BaseTool.subclasses.freeze

oauth_mode = ENV["BASECAMP_CLIENT_ID"] && !ENV["BASECAMP_CLIENT_ID"].empty? &&
  ENV["BASECAMP_CLIENT_SECRET"] && !ENV["BASECAMP_CLIENT_SECRET"].empty?

required_vars = ["BASECAMP_ACCOUNT_ID"]
required_vars << "BASECAMP_ACCESS_TOKEN" unless oauth_mode

required_vars.each do |var|
  raise "Missing required environment variable: #{var}" if ENV[var].nil? || ENV[var].empty?
end

if oauth_mode
  token_path = ENV.fetch("BASECAMP_TOKEN_PATH", Basecamp::TokenStore::DEFAULT_PATH)
  TOKEN_STORE = Basecamp::TokenStore.new(token_file_path: token_path)
  if ENV["BASECAMP_ACCESS_TOKEN"] && !ENV["BASECAMP_ACCESS_TOKEN"].empty?
    TOKEN_STORE.seed!(access_token: ENV["BASECAMP_ACCESS_TOKEN"])
  end

  refresher = Basecamp::OAuthRefresher.new(
    client_id: ENV.fetch("BASECAMP_CLIENT_ID"),
    client_secret: ENV.fetch("BASECAMP_CLIENT_SECRET"),
    token_store: TOKEN_STORE
  )

  BASECAMP_CLIENT = Basecamp::Client.new(
    access_token: TOKEN_STORE.access_token,
    account_id: ENV.fetch("BASECAMP_ACCOUNT_ID"),
    token_store: TOKEN_STORE,
    refresher: refresher
  )

  basecamp_client = BASECAMP_CLIENT
else
  basecamp_client = Basecamp::Client.new(
    access_token: ENV.fetch("BASECAMP_ACCESS_TOKEN"),
    account_id: ENV.fetch("BASECAMP_ACCOUNT_ID")
  )
end

SERVER = MCP::Server.new(
  name: "basecamp-mcp",
  version: "0.1.0",
  tools: TOOLS,
  server_context: {basecamp_client: basecamp_client},
  configuration: MCP::Configuration.new(protocol_version: "2025-06-18")
)

TRANSPORT = MCP::Server::Transports::StreamableHTTPTransport.new(SERVER, stateless: true)
SERVER.transport = TRANSPORT
