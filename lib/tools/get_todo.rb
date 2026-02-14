# frozen_string_literal: true

module Tools
  class GetTodo < BaseTool
    tool_name "get_todo"
    description "Get details of a specific to-do"
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
        todo = client.get("buckets/#{project_id}/todos/#{todo_id}.json")
        text_response(todo)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
