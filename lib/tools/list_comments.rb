# frozen_string_literal: true

module Tools
  class ListComments < BaseTool
    tool_name "list_comments"
    description "List comments on a recording (message, to-do, etc.)"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        recording_id: {type: "integer", description: "The recording ID (message, to-do, etc.)"}
      },
      required: ["project_id", "recording_id"]
    )

    class << self
      def call(project_id:, recording_id:, server_context:)
        client = basecamp_client(server_context)
        comments = client.get("buckets/#{project_id}/recordings/#{recording_id}/comments.json")
        text_response(comments)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
