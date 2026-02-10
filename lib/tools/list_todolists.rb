# frozen_string_literal: true

module Tools
  class ListTodolists < BaseTool
    tool_name "list_todolists"
    description "List all to-do lists in a project's todoset"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        todoset_id: {type: "integer", description: "The todoset ID"}
      },
      required: ["project_id", "todoset_id"]
    )

    class << self
      def call(project_id:, todoset_id:, server_context:)
        client = basecamp_client(server_context)
        todolists = client.get("/buckets/#{project_id}/todosets/#{todoset_id}/todolists.json")
        text_response(todolists)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
