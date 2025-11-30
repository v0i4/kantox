defmodule Kantox.Offer do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Kantox.Repo

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
    |> cast(attrs, [
      :product_code,
      :offer_type,
      :params,
      :active,
      :starts_at,
      :ends_at
    ])
    |> validate_required([
      :product_code,
      :offer_type,
      :params,
      :active,
      :starts_at,
      :ends_at
    ])
    |> validate_unique_offer_type_for_product()
  end

  defp validate_unique_offer_type_for_product(changeset) do
    product_code = get_field(changeset, :product_code)
    offer_type = get_field(changeset, :offer_type)
    offer_id = get_field(changeset, :id)

    if product_code && offer_type do
      query =
        from o in __MODULE__,
          where: o.product_code == ^product_code and o.offer_type == ^offer_type

      # Exclude current offer if updating (not inserting)
      query =
        if offer_id do
          from o in query, where: o.id != ^offer_id
        else
          query
        end

      case Repo.one(query) do
        nil ->
          changeset

        _existing_offer ->
          add_error(
            changeset,
            :product_code,
            "offer type already exists for this product"
          )
      end
    else
      changeset
    end
  end
end
