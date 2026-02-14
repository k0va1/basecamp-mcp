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
