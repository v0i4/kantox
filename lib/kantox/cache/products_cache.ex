defmodule Kantox.Cache.ProductsCache do
  @moduledoc """
  Products-specific cache layer using ETS.
  Provides high-performance, concurrent access to products.
  """

  alias Kantox.Cache.ETSCache
  alias Kantox.Products

  require Logger

  @cache_key_prefix :product_
  @all_products_key :all_products
  @ttl :timer.minutes(30)

  @doc """
  Gets all products from cache.
  If cache is empty or expired, loads from database.
  """
  def get_all do
    case ETSCache.get(@all_products_key) do
      nil ->
        refresh_all()

      products ->
        products
    end
  end

  @doc """
  Gets a product by code from cache.
  If not in cache, loads from database and caches it.
  """
  def get_by_code(code) do
    cache_key = product_cache_key(code)

    case ETSCache.get(cache_key) do
      nil ->
        case Products.get_by_code(code) do
          nil ->
            nil

          product ->
            ETSCache.put(cache_key, product, @ttl)
            product
        end

      product ->
        product
    end
  end

  @doc """
  Gets multiple products by codes from cache.
  Fetches missing products from database.
  """
  def get_by_codes(codes) do
    codes
    |> Enum.uniq()
    |> Enum.map(&get_by_code/1)
    |> Enum.reject(&is_nil/1)
    |> Map.new(&{&1.code, &1})
  end

  @doc """
  Refreshes all products cache from database.
  Returns the updated list of products.
  """
  def refresh_all do
    Logger.debug("Refreshing products cache from database")

    products = Products.all()
    ETSCache.put(@all_products_key, products, @ttl)

    # Also cache individual products
    Enum.each(products, fn product ->
      ETSCache.put(product_cache_key(product.code), product, @ttl)
    end)

    products
  end

  @doc """
  Invalidates a specific product cache by code.
  """
  def invalidate(code) do
    Logger.debug("Invalidating product cache for code: #{code}")
    ETSCache.delete(product_cache_key(code))
    ETSCache.delete(@all_products_key)
  end

  @doc """
  Invalidates all products cache.
  """
  def invalidate_all do
    Logger.debug("Invalidating all products cache")
    ETSCache.delete(@all_products_key)
  end

  defp product_cache_key(code), do: :"#{@cache_key_prefix}#{code}"
end

