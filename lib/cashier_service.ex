defmodule Kantox.CashierService do
  @moduledoc """
  Service for processing shopping baskets and applying discounts.
  """

  alias Kantox.OfferEngine
  alias Kantox.Products
  alias Kantox.ProductsCache

  @doc """
  Processes a basket of product codes and returns the total price after applying offers.

  ## Examples

      iex> CashierService.process(["GR1", "SR1", "GR1", "CF1"])
      22.45

  """
  def process(basket) do
    with true <- validate_basket(basket) do
      total =
        basket
        |> summarize()
        |> OfferEngine.process()

      {:ok, total}
    else
      false ->
        {:error, "invalid products in basket"}
    end
  end

  defp summarize(basket) do
    basket
    |> Enum.frequencies()
    |> Enum.map(fn {code, qty} ->
      product = Products.get_by_code(code)
      {product, qty}
    end)
  end

  def validate_basket(basket) do
    basket
    |> Enum.all?(fn product_code -> product_code in ProductsCache.get_all_product_codes() end)
  end
end
