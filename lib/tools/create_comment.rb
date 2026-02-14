module Tools
  class CreateComment < BaseTool
    tool_name "create_comment"
    description "Add a comment to a recording (message, to-do, etc.)"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        recording_id: {type: "integer", description: "The recording ID (message, to-do, etc.)"},
        content: {type: "string", description: "Comment body (HTML allowed)"}
      },
      required: ["project_id", "recording_id", "content"]
    )

    class << self
      def call(project_id:, recording_id:, content:, server_context:)
        client = basecamp_client(server_context)
        comment = client.post("buckets/#{project_id}/recordings/#{recording_id}/comments.json", {content: content})
        text_response(comment)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
