defmodule KantoxWeb.ProductControllerTest do
  use KantoxWeb.ConnCase

  alias Kantox.Products

  setup do
    # Create test products
    {:ok, gr1} = Products.create(%{name: "Green Tea", code: "GR1", price: 3.11})
    {:ok, sr1} = Products.create(%{name: "Strawberries", code: "SR1", price: 5.00})
    {:ok, cf1} = Products.create(%{name: "Coffee", code: "CF1", price: 11.23})

    %{products: [gr1, sr1, cf1]}
  end

  describe "GET /api/products" do
    test "lists all products", %{conn: conn} do
      conn = get(conn, ~p"/api/products")

      response = json_response(conn, 200)

      assert response["count"] == 3
      assert length(response["data"]) == 3

      # Verify product structure
      product = hd(response["data"])
      assert Map.has_key?(product, "id")
      assert Map.has_key?(product, "name")
      assert Map.has_key?(product, "code")
      assert Map.has_key?(product, "price")
    end

    test "returns correct product data", %{conn: conn} do
      conn = get(conn, ~p"/api/products")

      response = json_response(conn, 200)
      data = response["data"]

      # Find GR1 product
      gr1 = Enum.find(data, fn p -> p["code"] == "GR1" end)
      assert gr1["name"] == "Green Tea"
      assert gr1["price"] == 3.11

      # Find SR1 product
      sr1 = Enum.find(data, fn p -> p["code"] == "SR1" end)
      assert sr1["name"] == "Strawberries"
      assert sr1["price"] == 5.00

      # Find CF1 product
      cf1 = Enum.find(data, fn p -> p["code"] == "CF1" end)
      assert cf1["name"] == "Coffee"
      assert cf1["price"] == 11.23
    end
  end

  describe "POST /api/products" do
    test "creates a new product with valid data", %{conn: conn} do
      product_params = %{
        name: "Orange Juice",
        code: "OJ1",
        price: 7.50
      }

      conn = post(conn, ~p"/api/products", product: product_params)

      assert response = json_response(conn, 201)
      assert response["id"]
      assert response["name"] == "Orange Juice"
      assert response["code"] == "OJ1"
      assert response["price"] == 7.50
    end

    test "returns error with invalid data", %{conn: conn} do
      product_params = %{
        name: "",
        code: "",
        price: nil
      }

      conn = post(conn, ~p"/api/products", product: product_params)

      assert response = json_response(conn, 400)
      assert response["errors"]
      assert response["errors"]["name"]
      assert response["errors"]["code"]
      assert response["errors"]["price"]
    end

    test "returns error with missing fields", %{conn: conn} do
      product_params = %{
        name: "Incomplete Product"
      }

      conn = post(conn, ~p"/api/products", product: product_params)

      assert response = json_response(conn, 400)
      assert response["errors"]
      assert response["errors"]["code"]
      assert response["errors"]["price"]
    end

    test "returns error with duplicate code", %{conn: conn} do
      product_params = %{
        name: "Duplicate Green Tea",
        code: "GR1",
        price: 3.50
      }

      conn = post(conn, ~p"/api/products", product: product_params)

      assert response = json_response(conn, 400)
      assert response["errors"]
      assert response["errors"]["code"]
    end

    test "returns error with negative price", %{conn: conn} do
      product_params = %{
        name: "Invalid Product",
        code: "INV1",
        price: -5.00
      }

      conn = post(conn, ~p"/api/products", product: product_params)

      assert response = json_response(conn, 400)
      assert response["errors"]
      assert response["errors"]["price"]
    end
  end
end

