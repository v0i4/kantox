defmodule KantoxWeb.ProductController do
  use KantoxWeb, :controller

  def index(conn, _params) do
    products = Kantox.Products.all()
    render(conn, "index.json", %{products: products})
  end
end
