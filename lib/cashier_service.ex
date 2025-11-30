defmodule Kantox.CashierService do
  @moduledoc """
  Service for processing shopping baskets and applying discounts.
  Optimized with ETS-based caching for high performance.
  """

  alias Kantox.OfferEngine
  alias Kantox.Cache.ProductsCache

  @max_basket_size 1000

  @doc """
  Processes a basket of product codes and returns detailed pricing information.

  ## Examples

      iex> CashierService.process(["GR1", "SR1", "GR1", "CF1"])
      {:ok, %{
        total: 22.45,
        full_price: 25.56,
        off_price: 3.11
      }}

  """
  def process(basket) when is_list(basket) and length(basket) <= @max_basket_size do
    with {:ok, products_map} <- load_products(basket),
         true <- validate_basket(basket, products_map) do
      result =
        basket
        |> summarize(products_map)
        |> OfferEngine.process()

      {:ok, result}
    else
      {:error, reason} ->
        {:error, reason}

      false ->
        {:error, "invalid products in basket"}
    end
  end

  def process(_basket) do
    {:error, "basket too large (max #{@max_basket_size} items)"}
  end

  defp load_products(basket) do
    codes = Enum.uniq(basket)
    products_map = ProductsCache.get_by_codes(codes)

    if map_size(products_map) == length(codes) do
      {:ok, products_map}
    else
      {:error, "some products not found"}
    end
  end

  defp summarize(basket, products_map) do
    basket
    |> Enum.frequencies()
    |> Enum.map(fn {code, qty} ->
      product = Map.get(products_map, code)
      {product, qty}
    end)
  end

  defp validate_basket(basket, products_map) do
    basket
    |> Enum.all?(fn product_code -> Map.has_key?(products_map, product_code) end)
  end
end
