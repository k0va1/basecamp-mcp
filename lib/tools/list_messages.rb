# frozen_string_literal: true

module Tools
  class ListMessages < BaseTool
    tool_name "list_messages"
    description "List messages on a project's message board"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        message_board_id: {type: "integer", description: "The message board ID"}
      },
      required: ["project_id", "message_board_id"]
    )

    class << self
      def call(project_id:, message_board_id:, server_context:)
        client = basecamp_client(server_context)
        messages = client.get("buckets/#{project_id}/message_boards/#{message_board_id}/messages.json")
        text_response(messages)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
