require "minitest/autorun"
require "webmock/minitest"
require "tmpdir"
require_relative "../../lib/basecamp/errors"
require_relative "../../lib/basecamp/token_store"
require_relative "../../lib/basecamp/oauth_refresher"

WebMock.disable_net_connect!

class OAuthRefresherTest < Minitest::Test
  TOKEN_URL = "https://launchpad.37signals.com/authorization/token?type=refresh"

  def setup
    @tmpdir = Dir.mktmpdir
    @token_file = File.join(@tmpdir, "tokens.json")
    @store = Basecamp::TokenStore.new(token_file_path: @token_file)
    @store.update!(access_token: "old-token", refresh_token: "old-refresh", expires_in: -1)

    @refresher = Basecamp::OAuthRefresher.new(
      client_id: "test-client-id",
      client_secret: "test-client-secret",
      token_store: @store
    )
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_refresh_updates_token_store
    stub_request(:post, TOKEN_URL)
      .with(body: {
        "client_id" => "test-client-id",
        "client_secret" => "test-client-secret",
        "refresh_token" => "old-refresh"
      })
      .to_return(
        status: 200,
        body: JSON.generate({
          "access_token" => "new-token",
          "refresh_token" => "new-refresh",
          "expires_in" => 1_209_600
        }),
        headers: {"Content-Type" => "application/json"}
      )

    result = @refresher.refresh!

    assert_equal "new-token", result
    assert_equal "new-token", @store.access_token
    assert_equal "new-refresh", @store.refresh_token
  end

  def test_refresh_preserves_refresh_token_when_not_returned
    stub_request(:post, TOKEN_URL)
      .to_return(
        status: 200,
        body: JSON.generate({
          "access_token" => "new-token",
          "expires_in" => 1_209_600
        }),
        headers: {"Content-Type" => "application/json"}
      )

    @refresher.refresh!

    assert_equal "new-token", @store.access_token
    assert_equal "old-refresh", @store.refresh_token
  end

  def test_refresh_raises_on_failure
    stub_request(:post, TOKEN_URL)
      .to_return(status: 401, body: "Unauthorized")

    assert_raises(Basecamp::AuthenticationError) { @refresher.refresh! }
  end

  def test_refresh_raises_on_server_error
    stub_request(:post, TOKEN_URL)
      .to_return(status: 500, body: "Internal Server Error")

    assert_raises(Basecamp::AuthenticationError) { @refresher.refresh! }
  end
end
