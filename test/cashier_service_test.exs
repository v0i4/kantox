defmodule Kantox.CashierServiceTest do
  use Kantox.DataCase, async: false

  alias Kantox.CashierService
  alias Kantox.Products

  setup do
    # Create test products with offers
    {:ok, _gr1} = Products.create(%{name: "Green Tea", code: "GR1", price: 3.11})
    {:ok, _sr1} = Products.create(%{name: "Strawberries", code: "SR1", price: 5.00})
    {:ok, _cf1} = Products.create(%{name: "Coffee", code: "CF1", price: 11.23})

    # Create test products WITHOUT offers (to test regular pricing)
    {:ok, _ch1} = Products.create(%{name: "Chocolate", code: "CH1", price: 2.50})
    {:ok, _wa1} = Products.create(%{name: "Water", code: "WA1", price: 1.00})
    {:ok, _ju1} = Products.create(%{name: "Orange Juice", code: "JU1", price: 3.75})
    {:ok, _br1} = Products.create(%{name: "Bread", code: "BR1", price: 2.25})

    # Create test offers (only for GR1, SR1, CF1)
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

  test "process/1 with products that have offers" do
    basket_1 = ["GR1", "SR1", "GR1", "GR1", "CF1"]
    basket_2 = ["GR1", "GR1"]
    basket_3 = ["SR1", "SR1", "GR1", "SR1"]
    basket_4 = ["GR1", "CF1", "SR1", "CF1", "CF1"]

    assert {:ok, 22.45} = CashierService.process(basket_1)
    assert {:ok, 3.11} = CashierService.process(basket_2)
    assert {:ok, 16.61} = CashierService.process(basket_3)
    assert {:ok, 30.57} = CashierService.process(basket_4)
  end

  test "process/1 with products WITHOUT offers (regular pricing)" do
    # CH1 = 2.50, WA1 = 1.00, JU1 = 3.75, BR1 = 2.25
    
    # Single product without offer
    basket_1 = ["CH1"]
    assert {:ok, 2.50} = CashierService.process(basket_1)

    # Multiple same products without offer
    basket_2 = ["WA1", "WA1", "WA1"]
    assert {:ok, 3.0} = CashierService.process(basket_2)

    # Multiple different products without offers
    basket_3 = ["CH1", "WA1", "JU1"]
    # 2.50 + 1.00 + 3.75 = 7.25
    assert {:ok, 7.25} = CashierService.process(basket_3)

    # Multiple quantities of different products without offers
    basket_4 = ["BR1", "BR1", "CH1", "WA1", "WA1", "JU1"]
    # (2.25 * 2) + 2.50 + (1.00 * 2) + 3.75 = 4.50 + 2.50 + 2.00 + 3.75 = 12.75
    assert {:ok, 12.75} = CashierService.process(basket_4)
  end

  test "process/1 with MIXED products (with and without offers)" do
    # Mixing products with offers and without offers
    
    # GR1 with BOGOF + CH1 without offer
    basket_1 = ["GR1", "GR1", "CH1"]
    # GR1: 2 items with BOGOF = pay for 1 = 3.11
    # CH1: 1 item = 2.50
    # Total: 3.11 + 2.50 = 5.61
    assert {:ok, 5.61} = CashierService.process(basket_1)

    # SR1 with bulk discount + WA1 without offer
    basket_2 = ["SR1", "SR1", "SR1", "WA1", "WA1"]
    # SR1: 3 items with bulk = 3 * 4.50 = 13.50
    # WA1: 2 items = 2 * 1.00 = 2.00
    # Total: 13.50 + 2.00 = 15.50
    assert {:ok, 15.50} = CashierService.process(basket_2)

    # CF1 with take_3_pay_for_2 + JU1 without offer
    basket_3 = ["CF1", "CF1", "CF1", "JU1"]
    # CF1: 3 items with take_3_pay_for_2 = 3 * (2/3 * 11.23) = 3 * 7.486666... = 22.46
    # JU1: 1 item = 3.75
    # Total: 22.46 + 3.75 = 26.21
    assert {:ok, 26.21} = CashierService.process(basket_3)

    # Complex basket with multiple products with and without offers
    basket_4 = ["GR1", "GR1", "SR1", "CH1", "WA1", "CF1"]
    # GR1: 2 items with BOGOF = 3.11
    # SR1: 1 item (no bulk) = 5.00
    # CH1: 1 item = 2.50
    # WA1: 1 item = 1.00
    # CF1: 1 item (no take_3_pay_for_2) = 11.23
    # Total: 3.11 + 5.00 + 2.50 + 1.00 + 11.23 = 22.84
    assert {:ok, 22.84} = CashierService.process(basket_4)
  end

  test "process/1 with products that do NOT reach offer threshold" do
    # Products with offers but quantities don't trigger the discount
    
    # SR1 bulk requires 3+ items, only buying 2
    basket_1 = ["SR1", "SR1"]
    # 2 * 5.00 = 10.00 (no bulk discount)
    assert {:ok, 10.0} = CashierService.process(basket_1)

    # CF1 take_3_pay_for_2 requires 3+ items, only buying 2
    basket_2 = ["CF1", "CF1"]
    # 2 * 11.23 = 22.46 (no discount)
    assert {:ok, 22.46} = CashierService.process(basket_2)

    # GR1 BOGOF with odd quantity (3 items = pay for 2)
    basket_3 = ["GR1", "GR1", "GR1"]
    # 3 items BOGOF = ceil(3/2) = 2 items charged = 2 * 3.11 = 6.22
    assert {:ok, 6.22} = CashierService.process(basket_3)
  end

  test "process/1 with empty basket" do
    basket = []
    assert {:ok, total} = CashierService.process(basket)
    assert total == 0.0
  end

  test "process/1 returns error for invalid product code" do
    basket = ["INVALID_CODE"]
    assert {:error, "some products not found"} = CashierService.process(basket)
  end

  test "process/1 returns error when mixing valid and invalid product codes" do
    basket = ["GR1", "INVALID", "SR1"]
    assert {:error, "some products not found"} = CashierService.process(basket)
  end
end
