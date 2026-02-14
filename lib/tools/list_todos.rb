module Tools
  class ListTodos < BaseTool
    tool_name "list_todos"
    description "List all to-dos in a to-do list"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        todolist_id: {type: "integer", description: "The to-do list ID"}
      },
      required: ["project_id", "todolist_id"]
    )

    class << self
      def call(project_id:, todolist_id:, server_context:)
        client = basecamp_client(server_context)
        todos = client.get("buckets/#{project_id}/todolists/#{todolist_id}/todos.json")
        text_response(todos)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
