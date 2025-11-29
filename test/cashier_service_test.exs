defmodule Kantox.CashierServiceTest do
  use Kantox.DataCase

  alias Kantox.CashierService
  alias Kantox.Products

  setup do
    # Create test products
    {:ok, _gr1} = Products.create(%{name: "Green Tea", code: "GR1", price: 3.11})
    {:ok, _sr1} = Products.create(%{name: "Strawberries", code: "SR1", price: 5.00})
    {:ok, _cf1} = Products.create(%{name: "Coffee", code: "CF1", price: 11.23})

    :ok
  end

  test "process/1" do
    basket_1 = ["GR1", "SR1", "GR1", "GR1", "CF1"]
    basket_2 = ["GR1", "GR1"]
    basket_3 = ["SR1", "SR1", "GR1", "SR1"]
    basket_4 = ["GR1", "CF1", "SR1", "CF1", "CF1"]

    assert CashierService.process(basket_1) == 22.45
    assert CashierService.process(basket_2) == 3.11
    assert CashierService.process(basket_3) == 16.61
    assert CashierService.process(basket_4) == 30.57
  end
end
