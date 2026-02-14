# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

class ClientTest < Minitest::Test
  def setup
    @client = Basecamp::Client.new(access_token: "test-token", account_id: "12345")
    @base = "https://3.basecampapi.com/12345"
  end

  def test_get_parses_json
    stub_request(:get, "#{@base}/projects.json")
      .to_return(status: 200, body: '[{"id":1}]', headers: {"Content-Type" => "application/json"})

    result = @client.get("projects.json")
    assert_equal [{"id" => 1}], result
  end

  def test_post_sends_json_body
    stub_request(:post, "#{@base}/buckets/1/todos.json")
      .with(body: '{"content":"hello"}')
      .to_return(status: 201, body: '{"id":2}', headers: {"Content-Type" => "application/json"})

    result = @client.post("buckets/1/todos.json", {content: "hello"})
    assert_equal({"id" => 2}, result)
  end

  def test_put_sends_json_body
    stub_request(:put, "#{@base}/buckets/1/todos/2.json")
      .with(body: '{"content":"updated"}')
      .to_return(status: 200, body: '{"id":2,"content":"updated"}', headers: {"Content-Type" => "application/json"})

    result = @client.put("buckets/1/todos/2.json", {content: "updated"})
    assert_equal({"id" => 2, "content" => "updated"}, result)
  end

  def test_get_returns_nil_for_empty_body
    stub_request(:get, "#{@base}/empty.json")
      .to_return(status: 204, body: "", headers: {})

    assert_nil @client.get("empty.json")
  end

  def test_get_returns_nil_for_nil_body
    stub_request(:get, "#{@base}/nil.json")
      .to_return(status: 204, body: nil, headers: {})

    assert_nil @client.get("nil.json")
  end

  def test_401_raises_authentication_error
    stub_request(:get, "#{@base}/fail.json")
      .to_return(status: 401, body: "Unauthorized")

    assert_raises(Basecamp::AuthenticationError) { @client.get("fail.json") }
  end

  def test_404_raises_not_found_error
    stub_request(:get, "#{@base}/missing.json")
      .to_return(status: 404, body: "Not Found")

    assert_raises(Basecamp::NotFoundError) { @client.get("missing.json") }
  end

  def test_429_raises_rate_limit_error
    stub_request(:get, "#{@base}/rate.json")
      .to_return(status: 429, body: "Rate Limited", headers: {"Retry-After" => "0"})

    # faraday-retry intercepts 429 before handle_response can raise RateLimitError.
    # After exhausting retries, the final 429 response reaches handle_response.
    assert_raises(Basecamp::RateLimitError, ArgumentError) { @client.get("rate.json") }
  end

  def test_500_raises_api_error
    stub_request(:get, "#{@base}/error.json")
      .to_return(status: 500, body: "Internal Server Error")

    error = assert_raises(Basecamp::ApiError) { @client.get("error.json") }
    assert_equal 500, error.status
  end

  def test_sets_authorization_header
    stub = stub_request(:get, "#{@base}/projects.json")
      .with(headers: {"Authorization" => "Bearer test-token"})
      .to_return(status: 200, body: "[]")

    @client.get("projects.json")
    assert_requested(stub)
  end
end

class ClientWithRefreshTest < Minitest::Test
  TOKEN_URL = "https://launchpad.37signals.com/authorization/token?type=refresh"

  def setup
    @tmpdir = Dir.mktmpdir
    @token_file = File.join(@tmpdir, "tokens.json")
    @base = "https://3.basecampapi.com/12345"

    @store = Basecamp::TokenStore.new(token_file_path: @token_file)
    @store.update!(access_token: "current-token", refresh_token: "my-refresh", expires_in: 3600)

    @refresher = Basecamp::OAuthRefresher.new(
      client_id: "cid",
      client_secret: "csecret",
      token_store: @store
    )

    @client = Basecamp::Client.new(
      access_token: @store.access_token,
      account_id: "12345",
      token_store: @store,
      refresher: @refresher
    )
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_retries_on_401_after_refresh
    # First request returns 401, refresh succeeds, retry succeeds
    stub_request(:get, "#{@base}/projects.json")
      .to_return(
        {status: 401, body: "Unauthorized"},
        {status: 200, body: '[{"id":1}]', headers: {"Content-Type" => "application/json"}}
      )

    stub_request(:post, TOKEN_URL)
      .to_return(
        status: 200,
        body: JSON.generate({
          "access_token" => "refreshed-token",
          "refresh_token" => "new-refresh",
          "expires_in" => 1_209_600
        }),
        headers: {"Content-Type" => "application/json"}
      )

    result = @client.get("projects.json")
    assert_equal [{"id" => 1}], result
    assert_equal "refreshed-token", @store.access_token
  end

  def test_proactive_refresh_when_token_expires_soon
    @store.update!(access_token: "expiring-token", refresh_token: "my-refresh", expires_in: 100)

    stub_request(:post, TOKEN_URL)
      .to_return(
        status: 200,
        body: JSON.generate({
          "access_token" => "proactive-token",
          "refresh_token" => "new-refresh",
          "expires_in" => 1_209_600
        }),
        headers: {"Content-Type" => "application/json"}
      )

    stub_request(:get, "#{@base}/projects.json")
      .to_return(status: 200, body: '[{"id":2}]', headers: {"Content-Type" => "application/json"})

    result = @client.get("projects.json")
    assert_equal [{"id" => 2}], result
    assert_equal "proactive-token", @store.access_token
  end

  def test_no_refresh_without_token_store
    client = Basecamp::Client.new(access_token: "static-token", account_id: "12345")

    stub_request(:get, "#{@base}/fail.json")
      .to_return(status: 401, body: "Unauthorized")

    assert_raises(Basecamp::AuthenticationError) { client.get("fail.json") }
  end

  def test_raises_when_refresh_also_fails
    stub_request(:get, "#{@base}/projects.json")
      .to_return(status: 401, body: "Unauthorized")

    stub_request(:post, TOKEN_URL)
      .to_return(status: 401, body: "Unauthorized")

    assert_raises(Basecamp::AuthenticationError) { @client.get("projects.json") }
  end
end
