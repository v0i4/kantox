# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Kantox.Repo.insert!(%Kantox.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Kantox.Repo
alias Kantox.Product
alias Kantox.Offer
import Ecto.Query

# Helper function to insert product if it doesn't exist
insert_product = fn attrs ->
  case Repo.get_by(Product, code: attrs.code) do
    nil ->
      %Product{}
      |> Product.changeset(attrs)
      |> Repo.insert!()

    existing ->
      existing
  end
end

# Helper function to insert offer if it doesn't exist
insert_offer = fn attrs ->
  query =
    from o in Offer,
      where: o.product_code == ^attrs.product_code and o.offer_type == ^attrs.offer_type

  case Repo.one(query) do
    nil ->
      %Offer{}
      |> Offer.changeset(attrs)
      |> Repo.insert!()

    existing ->
      existing
  end
end

# Insert products
insert_product.(%{name: "Green Tea", code: "GR1", price: 3.11})
insert_product.(%{name: "Strawberries", code: "SR1", price: 5.00})
insert_product.(%{name: "Coffee", code: "CF1", price: 11.23})

# Insert offers
insert_offer.(%{
  product_code: "GR1",
  offer_type: "get_one_get_one_free",
  params: %{qty: 2, price: 3.11},
  active: true,
  starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
  ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
})

insert_offer.(%{
  product_code: "SR1",
  offer_type: "bulk",
  params: %{qty: 3, price: 4.50},
  active: true,
  starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
  ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
})

insert_offer.(%{
  product_code: "CF1",
  offer_type: "take_3_pay_for_2",
  params: %{qty: 3, price: 22.46},
  active: true,
  starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
  ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
})
