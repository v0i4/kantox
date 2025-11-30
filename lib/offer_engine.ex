defmodule Kantox.OfferEngine do
  @moduledoc """
  Module for processing offers and applying discounts.
  """

  alias Kantox.OffersCache

  def apply_discount(%{offer_type: "get_one_get_one_free"} = _offer, {product, qty} = _item) do
    # Buy one get one free: buy 2, pay for 1 (for odd quantities, round up)
    paid_qty = div(qty + 1, 2)
    Decimal.mult(Decimal.from_float(product.price), paid_qty)
  end

  def apply_discount(%{offer_type: "bulk"} = offer, {product, qty} = _item) do
    if qty >= offer.params["qty"] do
      Decimal.mult(offer.params["price"] |> Decimal.from_float(), qty)
    else
      Decimal.mult(product.price |> Decimal.from_float(), qty)
    end
  end

  def apply_discount(%{offer_type: "take_3_pay_for_2"} = offer, {product, qty} = _item) do
    if qty >= offer.params["qty"] do
      Decimal.mult(
        qty,
        Decimal.mult(Decimal.div(2, 3), product.price |> Decimal.from_float())
      )
    else
      Decimal.mult(product.price |> Decimal.from_float(), qty)
    end
  end

  def process(summarized_basket) do
    offers = OffersCache.get_offers()

    summarized_basket
    |> Enum.map(fn item ->
      {product, qty} = item

      offer =
        offers
        |> Enum.find(fn offer ->
          offer.product_code == product.code &&
            offer.active == true &&
            DateTime.compare(DateTime.utc_now(), offer.starts_at) in [:gt, :eq] &&
            DateTime.compare(DateTime.utc_now(), offer.ends_at) in [:lt, :eq]
        end)

      case offer do
        nil -> Decimal.mult(Decimal.from_float(product.price), qty)
        _ -> apply_discount(offer, item)
      end
    end)
    |> Enum.reduce(Decimal.new(0), &Decimal.add/2)
    |> Decimal.to_float()
  end
end
