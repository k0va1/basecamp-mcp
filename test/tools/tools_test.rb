require_relative "../test_helper"

module ToolTestHelper
  private

  def mock_client
    @mock_client ||= Minitest::Mock.new
  end

  def server_context
    {basecamp_client: mock_client}
  end

  def failing_client(method)
    client = Object.new
    client.define_singleton_method(method) { |*| raise Basecamp::Error, "fail" }
    {basecamp_client: client}
  end

  def assert_success_response(response)
    assert_instance_of MCP::Tool::Response, response
    refute response.error?
  end

  def assert_error_response(response)
    assert_instance_of MCP::Tool::Response, response
    assert response.error?
  end
end

class ListProjectsTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, [{"id" => 1, "name" => "Project"}], ["projects.json"])
    response = Tools::ListProjects.call(server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::ListProjects.call(server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class GetProjectTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"id" => 1}, ["projects/1.json"])
    response = Tools::GetProject.call(project_id: 1, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetProject.call(project_id: 1, server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class ListTodolistsTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, [{"id" => 10}], ["buckets/1/todosets/2/todolists.json"])
    response = Tools::ListTodolists.call(project_id: 1, todoset_id: 2, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::ListTodolists.call(project_id: 1, todoset_id: 2, server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class ListTodosTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, [{"id" => 20}], ["buckets/1/todolists/2/todos.json"])
    response = Tools::ListTodos.call(project_id: 1, todolist_id: 2, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::ListTodos.call(project_id: 1, todolist_id: 2, server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class GetTodoTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"id" => 5}, ["buckets/1/todos/5.json"])
    response = Tools::GetTodo.call(project_id: 1, todo_id: 5, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetTodo.call(project_id: 1, todo_id: 5, server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class CreateTodoTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:post, {"id" => 30}, ["buckets/1/todolists/2/todos.json", {content: "Buy milk"}])
    response = Tools::CreateTodo.call(project_id: 1, todolist_id: 2, content: "Buy milk", server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_with_optional_params
    expected_body = {content: "Task", description: "Details", assignee_ids: [1, 2], due_on: "2025-12-31"}
    mock_client.expect(:post, {"id" => 31}, ["buckets/1/todolists/2/todos.json", expected_body])
    response = Tools::CreateTodo.call(
      project_id: 1, todolist_id: 2, content: "Task",
      description: "Details", assignee_ids: [1, 2], due_on: "2025-12-31",
      server_context: server_context
    )
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::CreateTodo.call(project_id: 1, todolist_id: 2, content: "x", server_context: failing_client(:post))
    assert_error_response(response)
  end
end

class UpdateTodoTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:put, {"id" => 5}, ["buckets/1/todos/5.json", {content: "Updated"}])
    response = Tools::UpdateTodo.call(project_id: 1, todo_id: 5, content: "Updated", server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_with_optional_params
    expected_body = {content: "New", description: "Desc", assignee_ids: [3], due_on: "2025-06-01"}
    mock_client.expect(:put, {"id" => 5}, ["buckets/1/todos/5.json", expected_body])
    response = Tools::UpdateTodo.call(
      project_id: 1, todo_id: 5, content: "New",
      description: "Desc", assignee_ids: [3], due_on: "2025-06-01",
      server_context: server_context
    )
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::UpdateTodo.call(project_id: 1, todo_id: 5, server_context: failing_client(:put))
    assert_error_response(response)
  end
end

class CompleteTodoTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:post, nil, ["buckets/1/todos/5/completion.json"])
    response = Tools::CompleteTodo.call(project_id: 1, todo_id: 5, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::CompleteTodo.call(project_id: 1, todo_id: 5, server_context: failing_client(:post))
    assert_error_response(response)
  end
end

class ListMessagesTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, [{"id" => 100}], ["buckets/1/message_boards/3/messages.json"])
    response = Tools::ListMessages.call(project_id: 1, message_board_id: 3, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::ListMessages.call(project_id: 1, message_board_id: 3, server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class GetMessageTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"id" => 100}, ["buckets/1/messages/100.json"])
    response = Tools::GetMessage.call(project_id: 1, message_id: 100, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetMessage.call(project_id: 1, message_id: 100, server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class CreateMessageTest < Minitest::Test
  include ToolTestHelper

  def test_success
    expected_body = {subject: "Hello", content: "World"}
    mock_client.expect(:post, {"id" => 101}, ["buckets/1/message_boards/3/messages.json", expected_body])
    response = Tools::CreateMessage.call(
      project_id: 1, message_board_id: 3, subject: "Hello", content: "World",
      server_context: server_context
    )
    assert_success_response(response)
    mock_client.verify
  end

  def test_with_category_id
    expected_body = {subject: "Hello", content: "World", category_id: 7}
    mock_client.expect(:post, {"id" => 102}, ["buckets/1/message_boards/3/messages.json", expected_body])
    response = Tools::CreateMessage.call(
      project_id: 1, message_board_id: 3, subject: "Hello", content: "World",
      category_id: 7, server_context: server_context
    )
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::CreateMessage.call(
      project_id: 1, message_board_id: 3, subject: "x", content: "y",
      server_context: failing_client(:post)
    )
    assert_error_response(response)
  end
end

class ListCommentsTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, [{"id" => 200}], ["buckets/1/recordings/50/comments.json"])
    response = Tools::ListComments.call(project_id: 1, recording_id: 50, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::ListComments.call(project_id: 1, recording_id: 50, server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class CreateCommentTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:post, {"id" => 201}, ["buckets/1/recordings/50/comments.json", {content: "Nice!"}])
    response = Tools::CreateComment.call(project_id: 1, recording_id: 50, content: "Nice!", server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::CreateComment.call(project_id: 1, recording_id: 50, content: "x", server_context: failing_client(:post))
    assert_error_response(response)
  end
end

class ListPeopleTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, [{"id" => 1, "name" => "Alice"}], ["people.json"])
    response = Tools::ListPeople.call(server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::ListPeople.call(server_context: failing_client(:get))
    assert_error_response(response)
  end
end

class GetPersonTest < Minitest::Test
  include ToolTestHelper

  def test_success
    mock_client.expect(:get, {"id" => 42, "name" => "Bob"}, ["people/42.json"])
    response = Tools::GetPerson.call(person_id: 42, server_context: server_context)
    assert_success_response(response)
    mock_client.verify
  end

  def test_error
    response = Tools::GetPerson.call(person_id: 42, server_context: failing_client(:get))
    assert_error_response(response)
  end
end
