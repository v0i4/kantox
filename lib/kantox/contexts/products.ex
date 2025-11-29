defmodule Kantox.Products do
  @moduledoc """
  Context for managing products.
  """

  alias Kantox.Repo
  alias Kantox.Product

  @doc """
  Creates a product.

  ## Examples

      iex> create(%{name: "Green tea", code: "GR1", price: 3.11})
      {:ok, %Product{}}

  """
  def create(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
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
  Gets a product by code.

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
  Lists all products.

  ## Examples

      iex> all()
      [%Product{}, ...]

  """
  def all do
    Repo.all(Product)
  end
end
