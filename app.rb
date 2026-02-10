# frozen_string_literal: true

require "dotenv/load"
require "mcp"

require_relative "lib/basecamp/errors"
require_relative "lib/basecamp/client"
require_relative "lib/tools/base_tool"
require_relative "lib/tools/list_projects"
require_relative "lib/tools/get_project"
require_relative "lib/tools/list_todolists"
require_relative "lib/tools/list_todos"
require_relative "lib/tools/get_todo"
require_relative "lib/tools/create_todo"
require_relative "lib/tools/update_todo"
require_relative "lib/tools/complete_todo"
require_relative "lib/tools/list_messages"
require_relative "lib/tools/get_message"
require_relative "lib/tools/create_message"
require_relative "lib/tools/list_comments"
require_relative "lib/tools/create_comment"
require_relative "lib/tools/list_people"
require_relative "lib/tools/get_person"

TOOLS = [
  Tools::ListProjects,
  Tools::GetProject,
  Tools::ListTodolists,
  Tools::ListTodos,
  Tools::GetTodo,
  Tools::CreateTodo,
  Tools::UpdateTodo,
  Tools::CompleteTodo,
  Tools::ListMessages,
  Tools::GetMessage,
  Tools::CreateMessage,
  Tools::ListComments,
  Tools::CreateComment,
  Tools::ListPeople,
  Tools::GetPerson
].freeze

%w[BASECAMP_ACCESS_TOKEN BASECAMP_ACCOUNT_ID].each do |var|
  raise "Missing required environment variable: #{var}" if ENV[var].nil? || ENV[var].empty?
end

basecamp_client = Basecamp::Client.new(
  access_token: ENV.fetch("BASECAMP_ACCESS_TOKEN"),
  account_id: ENV.fetch("BASECAMP_ACCOUNT_ID")
)

SERVER = MCP::Server.new(
  name: "basecamp-mcp",
  version: "0.1.0",
  tools: TOOLS,
  server_context: {basecamp_client: basecamp_client}
)

TRANSPORT = MCP::Server::Transports::StreamableHTTPTransport.new(SERVER)
SERVER.transport = TRANSPORT
