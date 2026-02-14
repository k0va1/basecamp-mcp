require "logger"
require "stringio"

class RequestLogger
  def initialize(app, logger: Logger.new($stdout))
    @app = app
    @logger = logger
  end

  def call(env)
    body = env["rack.input"].read
    env["rack.input"] = StringIO.new(body)

    @logger.info("[REQ] #{env["REQUEST_METHOD"]} #{env["PATH_INFO"]} #{body}")

    status, headers, response_body = @app.call(env)

    response_parts = []
    response_body.each { |part| response_parts << part }

    @logger.info("[RES] #{status} #{response_parts.join}")

    [status, headers, response_parts]
  end
end
