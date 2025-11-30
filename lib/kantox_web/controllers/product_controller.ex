defmodule KantoxWeb.ProductController do
  use KantoxWeb, :controller

  def index(conn, _params) do
    products = Kantox.Products.all()
    render(conn, "index.json", %{products: products})
  end

  def create(conn, %{"product" => product_params}) do
    with {:ok, product} <- Kantox.Products.create(product_params) do
      conn
      |> put_status(:created)
      |> json(KantoxWeb.ProductJSON.data(product))
    else
      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> json(KantoxWeb.ProductJSON.error(%{changeset: changeset}))
    end
  end
end
