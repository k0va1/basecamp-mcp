# Validates Bearer token on incoming requests when MCP_AUTH_TOKEN is set.
# Returns 401 if the token is missing or incorrect.
class TokenAuth
  def initialize(app, token:)
    @app = app
    @token = token
  end

  def call(env)
    return @app.call(env) unless @token

    auth = env["HTTP_AUTHORIZATION"]
    if auth&.start_with?("Bearer ") && Rack::Utils.secure_compare(auth.delete_prefix("Bearer "), @token)
      @app.call(env)
    else
      [401, {"content-type" => "application/json"}, ['{"error":"Unauthorized"}']]
    end
  end
end
