# frozen_string_literal: true

module Tools
  class UpdateTodolist < BaseTool
    tool_name "update_todolist"
    description "Update an existing to-do list"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        todolist_id: {type: "integer", description: "The to-do list ID"},
        name: {type: "string", description: "New name for the to-do list"},
        description: {type: "string", description: "New description (HTML allowed)"}
      },
      required: ["project_id", "todolist_id", "name", "description"]
    )

    class << self
      def call(project_id:, todolist_id:, name:, description:, server_context:)
        client = basecamp_client(server_context)
        todolist = client.put("buckets/#{project_id}/todolists/#{todolist_id}.json", {name: name, description: description})
        text_response(todolist)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
