defmodule Kantox.Offer do
  use Ecto.Schema

  schema "offers" do
    field :product_code, :string
    field :offer_type, :string
    field :params, :map
    field :active, :boolean
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime
    timestamps()
  end

  def changeset(offer, attrs) do
    offer
    |> Ecto.Changeset.cast(attrs, [
      :product_code,
      :offer_type,
      :params,
      :active,
      :starts_at,
      :ends_at
    ])
    |> Ecto.Changeset.validate_required([
      :product_code,
      :offer_type,
      :params,
      :active,
      :starts_at,
      :ends_at
    ])
  end
end
