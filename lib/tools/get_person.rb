# frozen_string_literal: true

module Tools
  class GetPerson < BaseTool
    tool_name "get_person"
    description "Get details of a specific person"
    input_schema(
      properties: {
        person_id: {type: "integer", description: "The person ID"}
      },
      required: ["person_id"]
    )

    class << self
      def call(person_id:, server_context:)
        client = basecamp_client(server_context)
        person = client.get("/people/#{person_id}.json")
        text_response(person)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
