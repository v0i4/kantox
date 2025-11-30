defmodule KantoxWeb.BasketControllerTest do
  use KantoxWeb.ConnCase

  alias Kantox.Products
  alias Kantox.Offers

  setup do
    # Create test products
    {:ok, _gr1} = Products.create(%{name: "Green Tea", code: "GR1", price: 3.11})
    {:ok, _sr1} = Products.create(%{name: "Strawberries", code: "SR1", price: 5.00})
    {:ok, _cf1} = Products.create(%{name: "Coffee", code: "CF1", price: 11.23})

    # Create test offers
    {:ok, _offer} =
      Offers.create(%{
        product_code: "GR1",
        offer_type: "get_one_get_one_free",
        params: %{qty: 2, price: 3.11},
        active: true,
        starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
        ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
      })

    {:ok, _offer2} =
      Offers.create(%{
        product_code: "SR1",
        offer_type: "bulk",
        params: %{qty: 3, price: 4.50},
        active: true,
        starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
        ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
      })

    {:ok, _offer3} =
      Offers.create(%{
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

  describe "POST /api/baskets" do
    test "processes basket with buy-one-get-one-free offer", %{conn: conn} do
      basket = ["GR1", "GR1"]

      conn =
        post(conn, ~p"/api/baskets", %{
          basket: basket
        })

      response = json_response(conn, 200)
      assert response["total"] == 3.11
      assert response["full_price"] == 6.22
      assert response["off_price"] == 3.11
      assert response["status"] == "success"
    end

    test "processes basket with multiple products", %{conn: conn} do
      # GR1, SR1, CF1 without quantities to trigger discounts
      basket = ["GR1", "SR1", "CF1"]

      conn =
        post(conn, ~p"/api/baskets", %{
          basket: basket
        })

      response = json_response(conn, 200)
      assert response["status"] == "success"
      assert response["total"] == 19.34
      assert response["full_price"] == 19.34
      assert response["off_price"] == 0.0
    end

    test "processes basket with multiple quantities", %{conn: conn} do
      basket = ["GR1", "GR1", "GR1", "GR1"]

      conn =
        post(conn, ~p"/api/baskets", %{
          basket: basket
        })

      response = json_response(conn, 200)
      assert response["status"] == "success"
      # 4 GR1 with BOGOF = pay for 2 = 6.22
      assert response["total"] == 6.22
      assert response["full_price"] == 12.44
      assert response["off_price"] == 6.22
    end

    test "processes empty basket", %{conn: conn} do
      conn =
        post(conn, ~p"/api/baskets", %{
          basket: []
        })

      response = json_response(conn, 200)
      assert response["status"] == "success"
      assert response["total"] == 0.0
      assert response["full_price"] == 0.0
      assert response["off_price"] == 0.0
    end

    test "processes basket with bulk discount", %{conn: conn} do
      basket = ["SR1", "SR1", "SR1"]

      conn =
        post(conn, ~p"/api/baskets", %{
          basket: basket
        })

      response = json_response(conn, 200)
      assert response["status"] == "success"
      assert response["total"] == 13.5
      assert response["full_price"] == 15.0
      assert response["off_price"] == 1.5
    end

    test "processes basket with take_3_pay_for_2 discount", %{conn: conn} do
      basket = ["CF1", "CF1", "CF1"]

      conn =
        post(conn, ~p"/api/baskets", %{
          basket: basket
        })

      response = json_response(conn, 200)
      assert response["status"] == "success"
      assert response["total"] == 22.46
      assert response["full_price"] == 33.69
      assert response["off_price"] == 11.23
    end
  end
end
