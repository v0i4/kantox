defmodule Kantox.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :code, :string
    field :price, :float
    timestamps()
  end

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :code, :price])
    |> validate_required([:name, :code, :price])
    |> validate_number(:price, greater_than: 0)
    |> validate_length(:name, min: 1)
    |> validate_length(:code, min: 1)
    |> unique_constraint(:code)
  end
end
