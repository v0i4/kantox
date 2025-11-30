defmodule Kantox.Cache.ETSCacheTest do
  use ExUnit.Case, async: true

  alias Kantox.Cache.ETSCache

  setup do
    # Clear cache locally before each test (no broadcast in tests)
    ETSCache.clear_local()
    :ok
  end

  describe "get/1 and put/2" do
    test "stores and retrieves values" do
      assert ETSCache.get(:test_key) == nil

      ETSCache.put(:test_key, "test_value")
      assert ETSCache.get(:test_key) == "test_value"
    end

    test "stores complex data structures" do
      data = %{id: 1, name: "Test", items: [1, 2, 3]}

      ETSCache.put(:complex, data)
      assert ETSCache.get(:complex) == data
    end

    test "overwrites existing values" do
      ETSCache.put(:key, "value1")
      assert ETSCache.get(:key) == "value1"

      ETSCache.put(:key, "value2")
      assert ETSCache.get(:key) == "value2"
    end
  end

  describe "delete/1" do
    test "removes a key from cache" do
      ETSCache.put(:key, "value")
      assert ETSCache.get(:key) == "value"

      ETSCache.delete(:key)
      assert ETSCache.get(:key) == nil
    end
  end

  describe "clear/0" do
    test "removes all keys from cache" do
      ETSCache.put(:key1, "value1")
      ETSCache.put(:key2, "value2")
      ETSCache.put(:key3, "value3")

      assert ETSCache.size() == 3

      ETSCache.clear_local()
      assert ETSCache.size() == 0
    end
  end

  describe "keys/0" do
    test "returns all keys in cache" do
      ETSCache.put(:key1, "value1")
      ETSCache.put(:key2, "value2")
      ETSCache.put(:key3, "value3")

      keys = ETSCache.keys() |> Enum.sort()
      assert keys == [:key1, :key2, :key3]
    end

    test "returns empty list when cache is empty" do
      ETSCache.clear()
      assert ETSCache.keys() == []
    end
  end

  describe "size/0" do
    test "returns the number of entries in cache" do
      assert ETSCache.size() == 0

      ETSCache.put(:key1, "value1")
      assert ETSCache.size() == 1

      ETSCache.put(:key2, "value2")
      assert ETSCache.size() == 2

      ETSCache.delete(:key1)
      assert ETSCache.size() == 1
    end
  end

  describe "TTL expiration" do
    test "removes expired entries" do
      # Put with 100ms TTL
      ETSCache.put(:short_lived, "value", 100)
      assert ETSCache.get(:short_lived) == "value"

      # Wait for expiration
      Process.sleep(150)
      assert ETSCache.get(:short_lived) == nil
    end

    test "keeps non-expired entries" do
      # Put with 1 hour TTL (default)
      ETSCache.put(:long_lived, "value")
      assert ETSCache.get(:long_lived) == "value"

      # After a short wait, should still be there
      Process.sleep(50)
      assert ETSCache.get(:long_lived) == "value"
    end
  end

  describe "concurrent access" do
    test "handles concurrent reads and writes" do
      # Write initial value
      ETSCache.put(:concurrent, 0)

      # Spawn multiple processes that increment the value
      tasks =
        for i <- 1..10 do
          Task.async(fn ->
            ETSCache.put(:"concurrent_#{i}", i)
            ETSCache.get(:"concurrent_#{i}")
          end)
        end

      # Wait for all tasks and verify results
      results = Task.await_many(tasks)
      assert results == Enum.to_list(1..10)
    end
  end

  describe "cluster synchronization" do
    test "broadcasts invalidation events via PubSub" do
      # Subscribe to invalidation events
      Phoenix.PubSub.subscribe(Kantox.PubSub, "cache:invalidate")

      # Put a value
      ETSCache.put(:sync_test, "value")

      # Delete should broadcast
      ETSCache.delete(:sync_test)

      # Verify we received the broadcast
      assert_receive {:cache_invalidate, :sync_test}, 100
    end

    test "broadcasts clear events via PubSub" do
      # Subscribe to invalidation events
      Phoenix.PubSub.subscribe(Kantox.PubSub, "cache:invalidate")

      # Clear should broadcast
      ETSCache.clear()

      # Verify we received the broadcast
      assert_receive {:cache_clear}, 100
    end

    test "handles received invalidation events" do
      # Put a value
      ETSCache.put(:remote_key, "value")
      assert ETSCache.get(:remote_key) == "value"

      # Simulate receiving invalidation from another node
      send(Process.whereis(Kantox.Cache.ETSCache), {:cache_invalidate, :remote_key})

      # Give it time to process
      Process.sleep(10)

      # Value should be deleted
      assert ETSCache.get(:remote_key) == nil
    end
  end
end

