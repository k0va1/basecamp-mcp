# frozen_string_literal: true

module Tools
  class CreateTodo < BaseTool
    tool_name "create_todo"
    description "Create a new to-do in a to-do list"
    input_schema(
      properties: {
        project_id: {type: "integer", description: "The project ID"},
        todolist_id: {type: "integer", description: "The to-do list ID"},
        content: {type: "string", description: "The to-do title/content"},
        description: {type: "string", description: "Detailed description (HTML allowed)"},
        assignee_ids: {type: "array", items: {type: "integer"}, description: "Array of person IDs to assign"},
        due_on: {type: "string", description: "Due date in YYYY-MM-DD format"}
      },
      required: ["project_id", "todolist_id", "content"]
    )

    class << self
      def call(project_id:, todolist_id:, content:, description: nil, assignee_ids: nil, due_on: nil, server_context:)
        client = basecamp_client(server_context)
        body = {content: content}
        body[:description] = description if description
        body[:assignee_ids] = assignee_ids if assignee_ids
        body[:due_on] = due_on if due_on

        todo = client.post("/buckets/#{project_id}/todolists/#{todolist_id}/todos.json", body)
        text_response(todo)
      rescue Basecamp::Error => e
        error_response(e.message)
      end
    end
  end
end
