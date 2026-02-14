# frozen_string_literal: true

module Tools
  class UpdateTodo < BaseTool
    tool_name "update_todo"
    description "Update an existing to-do"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        todo_id: {type: "integer", description: "The to-do ID"},
        content: {type: "string", description: "New title/content"},
        description: {type: "string", description: "New description (HTML allowed)"},
        assignee_ids: {type: "array", items: {type: "integer"}, description: "Array of person IDs to assign"},
        due_on: {type: "string", description: "Due date in YYYY-MM-DD format"}
      },
      required: ["project_id", "todo_id"]
    )

    class << self
      def call(project_id:, todo_id:, content: nil, description: nil, assignee_ids: nil, due_on: nil, server_context:)
        client = basecamp_client(server_context)
        body = {}
        body[:content] = content if content
        body[:description] = description if description
        body[:assignee_ids] = assignee_ids if assignee_ids
        body[:due_on] = due_on if due_on

        todo = client.put("buckets/#{project_id}/todos/#{todo_id}.json", body)
        text_response(todo)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
