require_relative "test_helper"
require "rack"
require_relative "../lib/middleware/token_auth"
require_relative "../lib/middleware/downcase_headers"

class TokenAuthTest < Minitest::Test
  def dummy_app
    ->(env) { [200, {"content-type" => "text/plain"}, ["OK"]] }
  end

  def test_passes_through_when_no_token_configured
    app = TokenAuth.new(dummy_app, token: nil)
    status, _, body = app.call({})
    assert_equal 200, status
    assert_equal ["OK"], body
  end

  def test_returns_401_when_token_required_but_missing
    app = TokenAuth.new(dummy_app, token: "secret")
    status, headers, _ = app.call({})
    assert_equal 401, status
    assert_equal "application/json", headers["content-type"]
  end

  def test_returns_401_when_token_is_wrong
    app = TokenAuth.new(dummy_app, token: "secret")
    status, _, _ = app.call({"HTTP_AUTHORIZATION" => "Bearer wrong"})
    assert_equal 401, status
  end

  def test_passes_through_on_correct_token
    app = TokenAuth.new(dummy_app, token: "secret")
    status, _, body = app.call({"HTTP_AUTHORIZATION" => "Bearer secret"})
    assert_equal 200, status
    assert_equal ["OK"], body
  end
end

class DowncaseHeadersTest < Minitest::Test
  def test_lowercases_all_header_keys
    inner_app = ->(_env) { [200, {"Content-Type" => "text/html", "X-Custom-Header" => "value"}, ["OK"]] }
    app = DowncaseHeaders.new(inner_app)
    _, headers, _ = app.call({})
    assert_equal "text/html", headers["content-type"]
    assert_equal "value", headers["x-custom-header"]
    refute headers.key?("Content-Type")
    refute headers.key?("X-Custom-Header")
  end

  def test_preserves_already_lowercase_headers
    inner_app = ->(_env) { [200, {"content-type" => "text/plain"}, ["OK"]] }
    app = DowncaseHeaders.new(inner_app)
    _, headers, _ = app.call({})
    assert_equal "text/plain", headers["content-type"]
  end
end
