# Basecamp MCP Server

An MCP (Model Context Protocol) server that exposes Basecamp 3 project management operations as tools. This allows AI assistants like Claude to interact with Basecamp — listing projects, managing to-dos, reading/posting messages, and more.

Built with Ruby, Sinatra, and the [mcp](https://github.com/modelcontextprotocol/ruby-sdk) gem using Streamable HTTP transport.

## Prerequisites

- Ruby 3.x
- Bundler
- A Basecamp 3 account with an API access token

## Setup

```bash
git clone <repo-url> && cd basecamp-mcp
bundle install
cp .env.example .env
```

Edit `.env` with your Basecamp credentials:

```
BASECAMP_ACCESS_TOKEN=your_access_token_here
BASECAMP_ACCOUNT_ID=your_account_id_here
```

You can obtain an access token via [Basecamp's OAuth 2 flow](https://github.com/basecamp/api/blob/master/sections/authentication.md) or by creating a personal integration.

## Running

```bash
bundle exec rackup
```

The server starts on `http://localhost:9292` by default.

- **MCP endpoint**: `POST /` — handles all MCP protocol messages
- **Health check**: `GET /health` — returns `{"status":"ok"}`

## Tools

### Projects
| Tool | Description |
|------|-------------|
| `list_projects` | List all active projects |
| `get_project` | Get details of a specific project |

### To-dos
| Tool | Description |
|------|-------------|
| `list_todolists` | List to-do lists in a project's todoset |
| `list_todos` | List to-dos in a to-do list |
| `get_todo` | Get details of a specific to-do |
| `create_todo` | Create a new to-do |
| `update_todo` | Update an existing to-do |
| `complete_todo` | Mark a to-do as completed |

### Messages
| Tool | Description |
|------|-------------|
| `list_messages` | List messages on a message board |
| `get_message` | Get details of a specific message |
| `create_message` | Post a new message |

### Comments
| Tool | Description |
|------|-------------|
| `list_comments` | List comments on a recording |
| `create_comment` | Add a comment to a recording |

### People
| Tool | Description |
|------|-------------|
| `list_people` | List all visible people |
| `get_person` | Get details of a specific person |

## MCP Client Configuration

To use with Claude Code or other MCP clients, add to your MCP config:

```json
{
  "mcpServers": {
    "basecamp": {
      "url": "http://localhost:9292/"
    }
  }
}
```

## Project Structure

```
basecamp-mcp/
├── Gemfile              # Dependencies
├── config.ru            # Rack entrypoint
├── app.rb               # Server setup and wiring
├── .env.example         # Environment variable template
└── lib/
    ├── basecamp/
    │   ├── client.rb    # Faraday HTTP client for Basecamp 3 API
    │   └── errors.rb    # Custom error classes
    └── tools/
        ├── base_tool.rb # Shared base class with helpers
        └── *.rb         # 15 individual tool classes
```

## Verification

```bash
# Health check
curl http://localhost:9292/health

# MCP initialize
curl -X POST http://localhost:9292/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1,"params":{"protocolVersion":"2025-03-26","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
```
