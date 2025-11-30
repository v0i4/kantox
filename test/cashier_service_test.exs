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
    # Basket 1: GR1 x3 (BOGOF), SR1 x1, CF1 x1
    # Full: (3 * 3.11) + 5.00 + 11.23 = 25.56
    # Total: 6.22 + 5.00 + 11.23 = 22.45
    # Off: 3.11
    basket_1 = ["GR1", "SR1", "GR1", "GR1", "CF1"]
    assert {:ok, result1} = CashierService.process(basket_1)
    assert result1.total == 22.45
    assert result1.full_price == 25.56
    assert result1.off_price == 3.11

    # Basket 2: GR1 x2 (BOGOF)
    # Full: 6.22, Total: 3.11, Off: 3.11
    basket_2 = ["GR1", "GR1"]
    assert {:ok, result2} = CashierService.process(basket_2)
    assert result2.total == 3.11
    assert result2.full_price == 6.22
    assert result2.off_price == 3.11

    # Basket 3: SR1 x3 (bulk), GR1 x1
    # Full: 18.11, Total: 16.61, Off: 1.50
    basket_3 = ["SR1", "SR1", "GR1", "SR1"]
    assert {:ok, result3} = CashierService.process(basket_3)
    assert result3.total == 16.61
    assert result3.full_price == 18.11
    assert result3.off_price == 1.5

    # Basket 4: GR1 x1, CF1 x3 (take_3_pay_for_2), SR1 x1
    # Full: 41.80, Total: 30.57, Off: 11.23
    basket_4 = ["GR1", "CF1", "SR1", "CF1", "CF1"]
    assert {:ok, result4} = CashierService.process(basket_4)
    assert result4.total == 30.57
    assert result4.full_price == 41.8
    assert result4.off_price == 11.23
  end

  test "process/1 with products WITHOUT offers (regular pricing)" do
    # CH1 = 2.50, WA1 = 1.00, JU1 = 3.75, BR1 = 2.25
    
    # Single product without offer
    basket_1 = ["CH1"]
    assert {:ok, result1} = CashierService.process(basket_1)
    assert result1.total == 2.50
    assert result1.full_price == 2.50
    assert result1.off_price == 0.0

    # Multiple same products without offer
    basket_2 = ["WA1", "WA1", "WA1"]
    assert {:ok, result2} = CashierService.process(basket_2)
    assert result2.total == 3.0
    assert result2.full_price == 3.0
    assert result2.off_price == 0.0

    # Multiple different products without offers
    basket_3 = ["CH1", "WA1", "JU1"]
    # 2.50 + 1.00 + 3.75 = 7.25
    assert {:ok, result3} = CashierService.process(basket_3)
    assert result3.total == 7.25
    assert result3.full_price == 7.25
    assert result3.off_price == 0.0

    # Multiple quantities of different products without offers
    basket_4 = ["BR1", "BR1", "CH1", "WA1", "WA1", "JU1"]
    # (2.25 * 2) + 2.50 + (1.00 * 2) + 3.75 = 12.75
    assert {:ok, result4} = CashierService.process(basket_4)
    assert result4.total == 12.75
    assert result4.full_price == 12.75
    assert result4.off_price == 0.0
  end

  test "process/1 with MIXED products (with and without offers)" do
    # GR1 with BOGOF + CH1 without offer
    basket_1 = ["GR1", "GR1", "CH1"]
    # Full: 8.72, Total: 5.61, Off: 3.11
    assert {:ok, result1} = CashierService.process(basket_1)
    assert result1.total == 5.61
    assert result1.full_price == 8.72
    assert result1.off_price == 3.11

    # SR1 with bulk discount + WA1 without offer
    basket_2 = ["SR1", "SR1", "SR1", "WA1", "WA1"]
    # Full: 17.00, Total: 15.50, Off: 1.50
    assert {:ok, result2} = CashierService.process(basket_2)
    assert result2.total == 15.50
    assert result2.full_price == 17.0
    assert result2.off_price == 1.5

    # CF1 with take_3_pay_for_2 + JU1 without offer
    basket_3 = ["CF1", "CF1", "CF1", "JU1"]
    # Full: 37.44, Total: 26.21, Off: 11.23
    assert {:ok, result3} = CashierService.process(basket_3)
    assert result3.total == 26.21
    assert result3.full_price == 37.44
    assert result3.off_price == 11.23

    # Complex basket with multiple products with and without offers
    basket_4 = ["GR1", "GR1", "SR1", "CH1", "WA1", "CF1"]
    # Full: 25.95, Total: 22.84, Off: 3.11
    assert {:ok, result4} = CashierService.process(basket_4)
    assert result4.total == 22.84
    assert result4.full_price == 25.95
    assert result4.off_price == 3.11
  end

  test "process/1 with products that do NOT reach offer threshold" do
    # SR1 bulk requires 3+ items, only buying 2
    basket_1 = ["SR1", "SR1"]
    assert {:ok, result1} = CashierService.process(basket_1)
    assert result1.total == 10.0
    assert result1.full_price == 10.0
    assert result1.off_price == 0.0

    # CF1 take_3_pay_for_2 requires 3+ items, only buying 2
    basket_2 = ["CF1", "CF1"]
    assert {:ok, result2} = CashierService.process(basket_2)
    assert result2.total == 22.46
    assert result2.full_price == 22.46
    assert result2.off_price == 0.0

    # GR1 BOGOF with odd quantity (3 items = pay for 2)
    basket_3 = ["GR1", "GR1", "GR1"]
    # Full: 9.33, Total: 6.22, Off: 3.11
    assert {:ok, result3} = CashierService.process(basket_3)
    assert result3.total == 6.22
    assert result3.full_price == 9.33
    assert result3.off_price == 3.11
  end

  test "process/1 with empty basket" do
    basket = []
    assert {:ok, result} = CashierService.process(basket)
    assert result.total == 0.0
    assert result.full_price == 0.0
    assert result.off_price == 0.0
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
