defmodule Kantox.OfferEngine do
  @moduledoc """
  Module for processing offers and applying discounts.
  """

  alias Kantox.Offers

  def apply_discount(%{offer_type: "get_one_get_one_free"} = offer, {product, qty} = _item) do
    charged_price = ceil(qty / offer.params["qty"])
    Decimal.mult(product.price |> Decimal.from_float(), charged_price)
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
    offers = Offers.all()

    summarized_basket
    |> Enum.map(fn item ->
      {product, qty} = item

      offer =
        offers
        |> Enum.find(fn offer ->
          offer.product_code == product.code &&
            offer.active == true &&
            DateTime.compare(DateTime.utc_now(), offer.starts_at) == :gt &&
            DateTime.compare(DateTime.utc_now(), offer.ends_at) == :lt
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
