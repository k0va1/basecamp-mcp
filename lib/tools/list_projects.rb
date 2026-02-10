# frozen_string_literal: true

module Tools
  class ListProjects < BaseTool
    tool_name "list_projects"
    description "List all active Basecamp projects"
    input_schema(properties: {})

    class << self
      def call(server_context:)
        client = basecamp_client(server_context)
        projects = client.get("/projects.json")
        text_response(projects)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
