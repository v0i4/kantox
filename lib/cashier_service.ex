defmodule Kantox.CashierService do
  @moduledoc """
  Service for processing shopping baskets and applying discounts.
  """

  alias Kantox.OfferEngine
  alias Kantox.Products

  @doc """
  Processes a basket of product codes and returns the total price after applying offers.

  ## Examples

      iex> CashierService.process(["GR1", "SR1", "GR1", "CF1"])
      22.45

  """
  def process(basket) do
    basket
    |> summarize()
    |> OfferEngine.process()
  end

  defp summarize(basket) do
    basket
    |> Enum.frequencies()
    |> Enum.map(fn {code, qty} ->
      product = Products.get_by_code(code)
      {product, qty}
    end)
  end
end
