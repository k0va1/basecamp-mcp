# frozen_string_literal: true

module Tools
  class CreateTodolist < BaseTool
    tool_name "create_todolist"
    description "Create a new to-do list in a project's todoset"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        todoset_id: {type: "integer", description: "The todoset ID"},
        name: {type: "string", description: "Name of the to-do list"},
        description: {type: "string", description: "Description of the to-do list (HTML allowed)"}
      },
      required: ["project_id", "todoset_id", "name"]
    )

    class << self
      def call(project_id:, todoset_id:, name:, description: nil, server_context:)
        client = basecamp_client(server_context)
        body = {name: name}
        body[:description] = description if description

        todolist = client.post("buckets/#{project_id}/todosets/#{todoset_id}/todolists.json", body)
        text_response(todolist)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
