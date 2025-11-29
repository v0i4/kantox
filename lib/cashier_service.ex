defmodule Kantox.CashierService do
  @moduledoc """
  Service for processing shopping baskets and applying discounts.
  """

  alias Kantox.Offers
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
    |> apply_discount()
    |> Decimal.to_float()
  end

  defp summarize(basket) do
    basket
    |> Enum.frequencies()
    |> Enum.map(fn {code, qty} ->
      product = Products.get_by_code(code)
      {product, qty}
    end)
  end

  defp apply_discount(summarized_basket) do
    offers = Offers.all()

    summarized_basket
    |> Enum.map(fn {product, qty} ->
      # Find offer matching the product code
      offer =
        Enum.find(offers, fn offer ->
          offer.id == product.code
        end)

      case offer do
        nil ->
          # No offer applies, use regular price
          Decimal.mult(Decimal.from_float(product.price), qty)

        offer ->
          # Apply the offer discount function
          offer.fun.(qty, %{price: Decimal.from_float(product.price)})
      end
    end)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
  end
end
