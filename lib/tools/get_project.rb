# frozen_string_literal: true

module Tools
  class GetProject < BaseTool
    tool_name "get_project"
    description "Get details of a specific Basecamp project"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"}
      },
      required: ["project_id"]
    )

    class << self
      def call(project_id:, server_context:)
        client = basecamp_client(server_context)
        project = client.get("projects/#{project_id}.json")
        text_response(project)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
