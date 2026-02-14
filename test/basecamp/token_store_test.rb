require "minitest/autorun"
require "tmpdir"
require_relative "../../lib/basecamp/token_store"

class TokenStoreTest < Minitest::Test
  def setup
    @tmpdir = Dir.mktmpdir
    @token_file = File.join(@tmpdir, "tokens.json")
  end

  def teardown
    FileUtils.remove_entry(@tmpdir)
  end

  def test_new_store_has_nil_tokens
    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    assert_nil store.access_token
    assert_nil store.refresh_token
    assert_nil store.expires_at
  end

  def test_update_persists_tokens
    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    store.update!(access_token: "abc", refresh_token: "xyz", expires_in: 3600)

    assert_equal "abc", store.access_token
    assert_equal "xyz", store.refresh_token
    assert_instance_of Time, store.expires_at
  end

  def test_update_writes_to_file
    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    store.update!(access_token: "abc", refresh_token: "xyz", expires_in: 3600)

    assert File.exist?(@token_file)
    data = JSON.parse(File.read(@token_file))
    assert_equal "abc", data["access_token"]
    assert_equal "xyz", data["refresh_token"]
    assert data["expires_at"]
  end

  def test_loads_existing_file
    File.write(@token_file, JSON.generate({
      "access_token" => "loaded",
      "refresh_token" => "loaded-refresh",
      "expires_at" => Time.now.to_f + 3600
    }))

    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    assert_equal "loaded", store.access_token
    assert_equal "loaded-refresh", store.refresh_token
  end

  def test_handles_corrupt_json
    File.write(@token_file, "not valid json{{{")

    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    assert_nil store.access_token
  end

  def test_handles_missing_file
    store = Basecamp::TokenStore.new(token_file_path: File.join(@tmpdir, "nonexistent.json"))
    assert_nil store.access_token
  end

  def test_expired_returns_true_when_no_expires_at
    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    assert store.expired?
  end

  def test_expired_returns_true_when_past
    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    store.update!(access_token: "a", refresh_token: "b", expires_in: -1)
    assert store.expired?
  end

  def test_expired_returns_false_when_future
    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    store.update!(access_token: "a", refresh_token: "b", expires_in: 3600)
    refute store.expired?
  end

  def test_expires_soon_returns_true_within_margin
    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    store.update!(access_token: "a", refresh_token: "b", expires_in: 200)
    assert store.expires_soon?(300)
  end

  def test_expires_soon_returns_false_outside_margin
    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    store.update!(access_token: "a", refresh_token: "b", expires_in: 3600)
    refute store.expires_soon?(300)
  end

  def test_seed_creates_file_when_missing
    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    store.seed!(access_token: "seeded")

    assert File.exist?(@token_file)
    assert_equal "seeded", store.access_token
  end

  def test_seed_does_not_overwrite_existing_file
    File.write(@token_file, JSON.generate({
      "access_token" => "existing",
      "refresh_token" => "existing-refresh",
      "expires_at" => Time.now.to_f + 3600
    }))

    store = Basecamp::TokenStore.new(token_file_path: @token_file)
    store.seed!(access_token: "new")

    assert_equal "existing", store.access_token
  end
end
