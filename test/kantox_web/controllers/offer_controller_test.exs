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
end

