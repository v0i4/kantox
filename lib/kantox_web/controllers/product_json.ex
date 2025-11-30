defmodule KantoxWeb.ProductJSON do
  @doc """
  Renders a list of products.
  """
  def index(%{products: products}) do
    %{
      data: for(product <- products, do: data(product)),
      count: length(products)
    }
  end

  @doc """
  Renders a single product.
  """
  def data(%{id: id, name: name, code: code, price: price}) do
    %{
      id: id,
      name: name,
      code: code,
      price: price
    }
  end
end
