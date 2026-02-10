# frozen_string_literal: true

module Tools
  class CompleteTodo < BaseTool
    tool_name "complete_todo"
    description "Mark a to-do as completed"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        todo_id: {type: "integer", description: "The to-do ID"}
      },
      required: ["project_id", "todo_id"]
    )

    class << self
      def call(project_id:, todo_id:, server_context:)
        client = basecamp_client(server_context)
        client.post("/buckets/#{project_id}/todos/#{todo_id}/completion.json")
        text_response({status: "completed", todo_id: todo_id})
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
