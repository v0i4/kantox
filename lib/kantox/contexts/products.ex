defmodule Kantox.Products do
  alias Kantox.Repo
  alias Kantox.Product

  def create(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  def get_by_id(id) do
    Repo.get(Product, id)
  end

  def all() do
    Repo.all(Product)
  end
end
