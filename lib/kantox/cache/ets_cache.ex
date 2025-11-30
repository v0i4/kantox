defmodule Kantox.Cache.ETSCache do
  @moduledoc """
  ETS-based cache implementation with supervision.
  Thread-safe, distributed, and scalable.
  """

  use GenServer
  require Logger

  @table_name :kantox_cache
  @default_ttl :timer.hours(1)

  # Client API

  @doc """
  Starts the ETS cache GenServer.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets a value from cache by key.
  Returns nil if not found or expired.
  """
  def get(key) do
    case :ets.lookup(@table_name, key) do
      [{^key, value, expires_at}] ->
        if expired?(expires_at) do
          delete(key)
          nil
        else
          value
        end

      [] ->
        nil
    end
  end

  @doc """
  Puts a value in cache with optional TTL (in milliseconds).
  """
  def put(key, value, ttl \\ @default_ttl) do
    expires_at = System.monotonic_time(:millisecond) + ttl
    :ets.insert(@table_name, {key, value, expires_at})
    :ok
  end

  @doc """
  Deletes a key from cache and broadcasts to cluster.
  """
  def delete(key) do
    :ets.delete(@table_name, key)
    broadcast_invalidation(key)
    :ok
  end

  @doc """
  Deletes a key from cache locally without broadcasting.
  Used internally when receiving broadcast events.
  """
  def delete_local(key) do
    :ets.delete(@table_name, key)
    :ok
  end

  @doc """
  Clears all cache entries and broadcasts to cluster.
  """
  def clear do
    :ets.delete_all_objects(@table_name)
    broadcast_clear()
    :ok
  end

  @doc """
  Clears all cache entries locally without broadcasting.
  """
  def clear_local do
    :ets.delete_all_objects(@table_name)
    :ok
  end

  @doc """
  Broadcasts cache invalidation to all nodes in cluster.
  """
  def broadcast_invalidation(key) do
    Phoenix.PubSub.broadcast(
      Kantox.PubSub,
      "cache:invalidate",
      {:cache_invalidate, key}
    )
  end

  @doc """
  Broadcasts cache clear to all nodes in cluster.
  """
  def broadcast_clear do
    Phoenix.PubSub.broadcast(
      Kantox.PubSub,
      "cache:invalidate",
      {:cache_clear}
    )
  end

  @doc """
  Gets all keys in the cache.
  """
  def keys do
    :ets.select(@table_name, [{{:"$1", :_, :_}, [], [:"$1"]}])
  end

  @doc """
  Gets the size of the cache.
  """
  def size do
    :ets.info(@table_name, :size)
  end

  # Server Callbacks

  @impl true
  def init(_opts) do
    # Create ETS table with public access and named_table
    table =
      :ets.new(@table_name, [
        :set,
        :public,
        :named_table,
        read_concurrency: true,
        write_concurrency: true
      ])

    # Subscribe to cache invalidation events across cluster
    Phoenix.PubSub.subscribe(Kantox.PubSub, "cache:invalidate")

    # Schedule periodic cleanup of expired entries
    schedule_cleanup()

    Logger.info("ETS Cache initialized: #{inspect(@table_name)}")

    {:ok, %{table: table}}
  end

  @impl true
  def handle_info(:cleanup, state) do
    cleanup_expired()
    schedule_cleanup()
    {:noreply, state}
  end

  @impl true
  def handle_info({:cache_invalidate, key}, state) do
    Logger.debug("Cache invalidation received for key: #{inspect(key)}")
    delete_local(key)
    {:noreply, state}
  end

  @impl true
  def handle_info({:cache_clear}, state) do
    Logger.debug("Cache clear received")
    :ets.delete_all_objects(@table_name)
    {:noreply, state}
  end

  @impl true
  def handle_info({:cache_invalidate_pattern, pattern}, state) do
    Logger.debug("Cache invalidation received for pattern: #{inspect(pattern)}")

    # Delete all keys matching pattern
    :ets.select_delete(@table_name, [
      {{:"$1", :_, :_}, [{:==, :"$1", pattern}], [true]}
    ])

    {:noreply, state}
  end

  # Private Functions

  defp expired?(expires_at) do
    System.monotonic_time(:millisecond) > expires_at
  end

  defp cleanup_expired do
    now = System.monotonic_time(:millisecond)

    # Delete all expired entries
    :ets.select_delete(@table_name, [
      {{:_, :_, :"$1"}, [{:<, :"$1", now}], [true]}
    ])
  end

  defp schedule_cleanup do
    # Run cleanup every 5 minutes
    Process.send_after(self(), :cleanup, :timer.minutes(5))
  end
end

