# Basecamp MCP Server

## Quick Reference

- **Run server**: `bundle exec rackup` (port 9292)
- **Health check**: `GET /health`
- **MCP endpoint**: `POST /` (requires `Accept: application/json, text/event-stream`)

## Architecture

Rack app with two mount points:
- `/` — MCP StreamableHTTPTransport handles all protocol routing
- `/health` — Sinatra mini-app

`app.rb` creates the MCP server and transport. `config.ru` wires them into Rack.

## Key Patterns

### Adding a new tool

1. Create `lib/tools/my_tool.rb` inheriting `Tools::BaseTool`
2. Define `tool_name`, `description`, `input_schema`
3. Implement `def call(..., server_context:)` as a class method
4. Use `basecamp_client(server_context)` to get the API client
5. Return `text_response(data)` or `error_response(msg)`
6. Add `require_relative` in `app.rb` and add to the `TOOLS` array

```ruby
class MyTool < BaseTool
  tool_name "my_tool"
  description "Does something"
  input_schema(properties: { id: { type: "integer" } }, required: ["id"])

  class << self
    def call(id:, server_context:)
      client = basecamp_client(server_context)
      result = client.get("/some/path/#{id}.json")
      text_response(result)
    rescue Basecamp::Error => e
      error_response(e.message)
    end
  end
end
```

### MCP gem gotchas

- `required: []` in `input_schema` raises a validation error — omit `required` entirely when there are no required params
- `MCP::Tool::Response.new(content_array, error: true)` — `error` is a keyword arg, not positional
- Tool `call` must be a **class method** (inside `class << self`)
- `server_context:` is passed automatically only if the method signature accepts it

### Rack 3 header casing

The MCP transport returns mixed-case headers (`Content-Type`) but Rack 3 requires lowercase. The `DowncaseHeaders` middleware in `config.ru` normalizes them.

## Basecamp API

- Base URL: `https://3.basecampapi.com/{account_id}`
- Auth: Bearer token in `Authorization` header
- Rate limiting: `faraday-retry` handles 429/503 with `Retry-After` support
- Error hierarchy: `Basecamp::Error` > `AuthenticationError`, `NotFoundError`, `RateLimitError`, `ApiError`

## Environment Variables

- `BASECAMP_ACCESS_TOKEN` — required
- `BASECAMP_ACCOUNT_ID` — required
- `MCP_AUTH_TOKEN` — optional; when set, all MCP requests must include `Authorization: Bearer <token>`. Uses `Rack::Utils.secure_compare` to prevent timing attacks. Middleware: `TokenAuth` in `config.ru`.
