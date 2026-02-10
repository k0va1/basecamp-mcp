# frozen_string_literal: true

module Tools
  class ListPeople < BaseTool
    tool_name "list_people"
    description "List all people visible to the current user"
    input_schema(properties: {})

    class << self
      def call(server_context:)
        client = basecamp_client(server_context)
        people = client.get("/people.json")
        text_response(people)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
