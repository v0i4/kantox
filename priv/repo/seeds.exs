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
Kantox.Repo.insert!(%Kantox.Product{name: "Green Tea", code: "GR1", price: 3.11})
Kantox.Repo.insert!(%Kantox.Product{name: "Strawberries", code: "SR1", price: 5.00})
Kantox.Repo.insert!(%Kantox.Product{name: "Coffee", code: "CF1", price: 11.23})

Kantox.Repo.insert!(%Kantox.Offer{
  product_code: "GR1",
  offer_type: "get_one_get_one_free",
  params: %{qty: 2, price: 3.11},
  active: true,
  starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
  ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
})
