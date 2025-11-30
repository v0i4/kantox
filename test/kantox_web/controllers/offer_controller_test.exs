defmodule KantoxWeb.OfferControllerTest do
  use KantoxWeb.ConnCase

  alias Kantox.Offers

  setup do
    # Create test offers
    {:ok, offer1} =
      Offers.create(%{
        product_code: "GR1",
        offer_type: "get_one_get_one_free",
        params: %{qty: 2, price: 3.11},
        active: true,
        starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
        ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
      })

    {:ok, offer2} =
      Offers.create(%{
        product_code: "SR1",
        offer_type: "bulk",
        params: %{qty: 3, price: 4.50},
        active: true,
        starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
        ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
      })

    %{offers: [offer1, offer2]}
  end

  describe "GET /api/offers" do
    test "lists all offers", %{conn: conn, offers: _offers} do
      conn = get(conn, ~p"/api/offers")

      response = json_response(conn, 200)

      assert response["count"] == 2
      assert length(response["data"]) == 2

      # Verify offer structure
      offer = hd(response["data"])
      assert Map.has_key?(offer, "id")
      assert Map.has_key?(offer, "product_code")
      assert Map.has_key?(offer, "offer_type")
      assert Map.has_key?(offer, "params")
      assert Map.has_key?(offer, "active")
      assert Map.has_key?(offer, "starts_at")
      assert Map.has_key?(offer, "ends_at")
    end

    test "returns correct offer data", %{conn: conn} do
      conn = get(conn, ~p"/api/offers")

      response = json_response(conn, 200)
      data = response["data"]

      # Find GR1 offer
      gr1_offer = Enum.find(data, fn o -> o["product_code"] == "GR1" end)
      assert gr1_offer["offer_type"] == "get_one_get_one_free"
      assert gr1_offer["active"] == true
      assert gr1_offer["params"]["qty"] == 2

      # Find SR1 offer
      sr1_offer = Enum.find(data, fn o -> o["product_code"] == "SR1" end)
      assert sr1_offer["offer_type"] == "bulk"
      assert sr1_offer["active"] == true
      assert sr1_offer["params"]["qty"] == 3
      assert sr1_offer["params"]["price"] == 4.50
    end

    test "returns active offers only", %{conn: conn} do
      conn = get(conn, ~p"/api/offers")

      response = json_response(conn, 200)
      data = response["data"]

      # All returned offers should be active
      assert Enum.all?(data, fn offer -> offer["active"] == true end)
    end
  end

  describe "POST /api/offers" do
    test "creates a new offer with valid data", %{conn: conn} do
      offer_params = %{
        product_code: "CF1",
        offer_type: "take_3_pay_for_2",
        params: %{qty: 3},
        active: true,
        starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
        ends_at: DateTime.utc_now() |> DateTime.add(14, :day) |> DateTime.truncate(:second)
      }

      conn = post(conn, ~p"/api/offers", offer: offer_params)

      assert response = json_response(conn, 201)
      assert response["id"]
      assert response["product_code"] == "CF1"
      assert response["offer_type"] == "take_3_pay_for_2"
      assert response["params"]["qty"] == 3
      assert response["active"] == true
      assert response["starts_at"]
      assert response["ends_at"]
    end

    test "creates a bulk offer", %{conn: conn} do
      offer_params = %{
        product_code: "TEST1",
        offer_type: "bulk",
        params: %{qty: 5, price: 10.00},
        active: true,
        starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
        ends_at: DateTime.utc_now() |> DateTime.add(30, :day) |> DateTime.truncate(:second)
      }

      conn = post(conn, ~p"/api/offers", offer: offer_params)

      assert response = json_response(conn, 201)
      assert response["offer_type"] == "bulk"
      assert response["params"]["qty"] == 5
      assert response["params"]["price"] == 10.00
    end

    test "returns error with invalid data", %{conn: conn} do
      offer_params = %{
        product_code: "",
        offer_type: "",
        params: nil,
        active: true,
        starts_at: nil,
        ends_at: nil
      }

      conn = post(conn, ~p"/api/offers", offer: offer_params)

      assert response = json_response(conn, 400)
      assert response["errors"]
      assert response["errors"]["product_code"]
      assert response["errors"]["offer_type"]
    end

    test "returns error with missing required fields", %{conn: conn} do
      offer_params = %{
        product_code: "TEST2",
        offer_type: "bulk"
      }

      conn = post(conn, ~p"/api/offers", offer: offer_params)

      assert response = json_response(conn, 400)
      assert response["errors"]
    end

    test "creates inactive offer", %{conn: conn} do
      offer_params = %{
        product_code: "INACTIVE1",
        offer_type: "get_one_get_one_free",
        params: %{qty: 2},
        active: false,
        starts_at: DateTime.utc_now() |> DateTime.truncate(:second),
        ends_at: DateTime.utc_now() |> DateTime.add(7, :day) |> DateTime.truncate(:second)
      }

      conn = post(conn, ~p"/api/offers", offer: offer_params)

      assert response = json_response(conn, 201)
      assert response["active"] == false
    end
  end
end

