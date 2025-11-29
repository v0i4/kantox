defmodule Kantox.Product do
  use Ecto.Schema

  schema "products" do
    field :name, :string
    field :code, :string
    field :price, :float
    timestamps()
  end

  def changeset(product, attrs) do
    product
    |> Ecto.Changeset.cast(attrs, [:name, :code, :price])
    |> Ecto.Changeset.validate_required([:name, :code, :price])
  end
end
