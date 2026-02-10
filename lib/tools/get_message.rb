# frozen_string_literal: true

module Tools
  class GetMessage < BaseTool
    tool_name "get_message"
    description "Get details of a specific message"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        message_id: {type: "integer", description: "The message ID"}
      },
      required: ["project_id", "message_id"]
    )

    class << self
      def call(project_id:, message_id:, server_context:)
        client = basecamp_client(server_context)
        message = client.get("/buckets/#{project_id}/messages/#{message_id}.json")
        text_response(message)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
