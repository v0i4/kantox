defmodule Kantox.Products do
  @moduledoc """
  Context for managing products.
  Uses ETS-based caching for high performance.
  """

  import Ecto.Query

  alias Kantox.Repo
  alias Kantox.Product
  alias Kantox.Cache.ProductsCache

  require Logger

  @doc """
  Creates a product and invalidates the cache.

  ## Examples

      iex> create(%{name: "Green tea", code: "GR1", price: 3.11})
      {:ok, %Product{}}

  """
  def create(attrs \\ %{}) do
    with {:ok, product} <-
           %Product{}
           |> Product.changeset(attrs)
           |> Repo.insert() do
      # Invalidate cache so next request fetches fresh data
      ProductsCache.invalidate(product.code)
      Logger.info("Created product #{product.code} and invalidated cache")

      {:ok, product}
    else
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Gets a product by ID.

  ## Examples

      iex> get_by_id(123)
      %Product{}

      iex> get_by_id(456)
      nil

  """
  def get_by_id(id) do
    Repo.get(Product, id)
  end

  @doc """
  Gets a product by code from cache if available.

  ## Examples

      iex> get_by_code("GR1")
      %Product{}

      iex> get_by_code("INVALID")
      nil

  """
  def get_by_code(code) do
    Repo.get_by(Product, code: code)
  end

  @doc """
  Gets multiple products by codes using cache.
  """
  def get_by_codes(codes) when is_list(codes) do
    from(p in Product, where: p.code in ^codes)
    |> Repo.all()
    |> Map.new(&{&1.code, &1})
  end

  @doc """
  Lists all products.

  ## Examples

      iex> all()
      [%Product{}, ...]

  """
  def all do
    Repo.all(Product)
  end
end
