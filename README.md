# Basecamp MCP Server

An MCP (Model Context Protocol) server that exposes Basecamp 3 project management operations as tools. This allows AI assistants like Claude to interact with Basecamp — listing projects, managing to-dos, reading/posting messages, and more.

Built with Ruby, Sinatra, and the [mcp](https://github.com/modelcontextprotocol/ruby-sdk) gem using Streamable HTTP transport.

## Prerequisites

- Ruby 3.2+
- Bundler
- A Basecamp 3 account with an API access token

## Setup

```bash
git clone https://github.com/k0va1/basecamp-mcp.git && cd basecamp-mcp
make install
cp .env.example .env
```

Edit `.env` with your Basecamp credentials:

```
BASECAMP_ACCESS_TOKEN=your_access_token_here
BASECAMP_ACCOUNT_ID=your_account_id_here
MCP_AUTH_TOKEN=optional_secret_token
```

You can obtain an access token via [Basecamp's OAuth 2 flow](https://github.com/basecamp/api/blob/master/sections/authentication.md) or by creating a personal integration.

### Authentication

Set `MCP_AUTH_TOKEN` to require a Bearer token on all MCP requests. When set, clients must include an `Authorization: Bearer <token>` header. When unset, the MCP endpoint is open (suitable for local development).

### OAuth2 Authorization Flow

To authenticate through the browser instead of manually obtaining tokens, add your OAuth2 credentials to `.env`:

```
BASECAMP_CLIENT_ID=your_oauth_client_id
BASECAMP_CLIENT_SECRET=your_oauth_client_secret
BASECAMP_REDIRECT_URI=http://localhost:9292/oauth/callback
```

Then visit `http://localhost:9292/oauth/authorize` in your browser. After authorizing with 37signals, tokens are saved automatically.

When OAuth credentials are set, the server also:
- Persists tokens to `.basecamp_tokens.json` (automatically gitignored)
- Proactively refreshes tokens 5 minutes before expiry
- Retries requests with a fresh token on 401 errors

If these variables are not set, the server uses the static `BASECAMP_ACCESS_TOKEN`.

## Running

```bash
bundle exec rackup
```

The server starts on `http://localhost:9292` by default.

- **MCP endpoint**: `POST /` — handles all MCP protocol messages
- **Health check**: `GET /health` — returns `{"status":"ok"}`
- **OAuth authorize**: `GET /oauth/authorize` — starts OAuth2 flow
- **OAuth callback**: `GET /oauth/callback` — handles OAuth2 redirect

Set `DEBUG=1` to enable request/response logging for both MCP and Basecamp API calls.

## Tools

### Projects
| Tool | Description |
|------|-------------|
| `list_projects` | List all active projects |
| `get_project` | Get details of a specific project |

### To-do Lists
| Tool | Description |
|------|-------------|
| `list_todolists` | List to-do lists in a project's todoset (supports `status` filter) |
| `get_todolist` | Get details of a specific to-do list |
| `create_todolist` | Create a new to-do list |
| `update_todolist` | Update an existing to-do list |

### To-dos
| Tool | Description |
|------|-------------|
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
      "url": "http://localhost:9292/",
      "headers": {
        "Authorization": "Bearer YOUR_MCP_AUTH_TOKEN"
      }
    }
  }
}
```

Omit the `headers` field if `MCP_AUTH_TOKEN` is not set.

## Development

```bash
make install    # install dependencies
make test       # run tests
make lint-fix   # fix linting issues
```

Tests use Minitest + WebMock. All HTTP calls are stubbed — no real API requests in tests.

## Project Structure

```
basecamp-mcp/
├── Gemfile              # Dependencies
├── Rakefile             # Test + lint tasks
├── Makefile             # Dev shortcuts
├── Dockerfile           # Multi-stage Docker build
├── config.ru            # Rack entrypoint
├── app.rb               # Server setup and wiring
├── .env.example         # Environment variable template
├── .standard.yml        # StandardRB linter config
└── lib/
    ├── basecamp/
    │   ├── client.rb          # Faraday HTTP client for Basecamp 3 API
    │   ├── errors.rb          # Custom error classes
    │   ├── token_store.rb     # Thread-safe token persistence
    │   └── oauth_refresher.rb # OAuth2 token refresh
    ├── oauth_app.rb           # OAuth2 authorize/callback Sinatra app
    ├── middleware/
    │   ├── downcase_headers.rb # Rack 3 header normalization
    │   ├── request_logger.rb   # DEBUG-gated request logger
    │   └── token_auth.rb       # Bearer token authentication
    └── tools/
        ├── base_tool.rb # Shared base class with helpers
        └── *.rb         # Auto-discovered tool classes
```

## Docker

### Build locally

```bash
docker build -t basecamp-mcp .
docker run -e BASECAMP_ACCESS_TOKEN=... -e BASECAMP_ACCOUNT_ID=... -p 9292:9292 basecamp-mcp
```

### Docker Compose

```yaml
services:
  basecamp-mcp:
    image: ghcr.io/k0va1/basecamp-mcp:latest
    ports:
      - "9292:9292"
    environment:
      - BASECAMP_ACCESS_TOKEN=${BASECAMP_ACCESS_TOKEN}
      - BASECAMP_ACCOUNT_ID=${BASECAMP_ACCOUNT_ID}
      - MCP_AUTH_TOKEN=${MCP_AUTH_TOKEN:-}
      - BASECAMP_CLIENT_ID=${BASECAMP_CLIENT_ID:-}
      - BASECAMP_CLIENT_SECRET=${BASECAMP_CLIENT_SECRET:-}
      - BASECAMP_REDIRECT_URI=${BASECAMP_REDIRECT_URI:-http://localhost:9292/oauth/callback}
      - BASECAMP_TOKEN_PATH=/app/data/.basecamp_tokens.json
    volumes:
      - basecamp-tokens:/app/data
    restart: unless-stopped

volumes:
  basecamp-tokens:
```

## Verification

```bash
# Health check
curl http://localhost:9292/health

# MCP initialize
curl -X POST http://localhost:9292/ \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1,"params":{"protocolVersion":"2025-06-18","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}'
```
