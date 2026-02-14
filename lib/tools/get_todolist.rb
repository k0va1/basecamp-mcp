module Tools
  class GetTodolist < BaseTool
    tool_name "get_todolist"
    description "Get details of a specific to-do list"
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
        todolist = client.get("buckets/#{project_id}/todolists/#{todolist_id}.json")
        text_response(todolist)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
