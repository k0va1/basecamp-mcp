# frozen_string_literal: true

module Tools
  class CreateMessage < BaseTool
    tool_name "create_message"
    description "Post a new message to a project's message board"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        message_board_id: {type: "integer", description: "The message board ID"},
        subject: {type: "string", description: "Message subject/title"},
        content: {type: "string", description: "Message body (HTML allowed)"},
        category_id: {type: "integer", description: "Message category ID"}
      },
      required: ["project_id", "message_board_id", "subject", "content"]
    )

    class << self
      def call(project_id:, message_board_id:, subject:, content:, category_id: nil, server_context:)
        client = basecamp_client(server_context)
        body = {subject: subject, content: content}
        body[:category_id] = category_id if category_id

        message = client.post("buckets/#{project_id}/message_boards/#{message_board_id}/messages.json", body)
        text_response(message)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
