defmodule Kantox.CashierServiceTest do
  use Kantox.DataCase

  alias Kantox.CashierService
  alias Kantox.Products

  setup do
    # Create test products
    {:ok, _gr1} = Products.create(%{name: "Green Tea", code: "GR1", price: 3.11})
    {:ok, _sr1} = Products.create(%{name: "Strawberries", code: "SR1", price: 5.00})
    {:ok, _cf1} = Products.create(%{name: "Coffee", code: "CF1", price: 11.23})

    # Create test offers
    {:ok, _offer_1} =
      Kantox.Offers.create(%{
        product_code: "GR1",
        offer_type: "get_one_get_one_free",
        params: %{qty: 2, price: 3.11},
        active: true,
        starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
        ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
      })

    {:ok, _offer_2} =
      Kantox.Offers.create(%{
        product_code: "SR1",
        offer_type: "bulk",
        params: %{qty: 3, price: 4.50},
        active: true,
        starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
        ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
      })

    {:ok, _offer_3} =
      Kantox.Offers.create(%{
        product_code: "CF1",
        offer_type: "take_3_pay_for_2",
        params: %{qty: 3, price: 22.46},
        active: true,
        starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
        ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
      })

    # Refresh caches to load data from database
    Kantox.Cache.OffersCache.refresh_offers()
    Kantox.Cache.ProductsCache.refresh_all()

    :ok
  end

  test "process/1" do
    basket_1 = ["GR1", "SR1", "GR1", "GR1", "CF1"]
    basket_2 = ["GR1", "GR1"]
    basket_3 = ["SR1", "SR1", "GR1", "SR1"]
    basket_4 = ["GR1", "CF1", "SR1", "CF1", "CF1"]

    assert {:ok, 22.45} = CashierService.process(basket_1)
    assert {:ok, 3.11} = CashierService.process(basket_2)
    assert {:ok, 16.61} = CashierService.process(basket_3)
    assert {:ok, 30.57} = CashierService.process(basket_4)
  end
end
