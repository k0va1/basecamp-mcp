require "mcp"

module Tools
  class BaseTool < MCP::Tool
    class << self
      private

      def basecamp_client(server_context)
        server_context[:basecamp_client]
      end

      def text_response(data)
        text = data.is_a?(String) ? data : JSON.generate(data)
        MCP::Tool::Response.new([{type: "text", text: text}])
      end

      def error_response(message)
        MCP::Tool::Response.new([{type: "text", text: message}], error: true)
      end
    end
  end
end
