defmodule Kantox.Offer do
  defstruct [
    :id,
    :qty,
    :fun
  ]

  def new(id, fun) do
    %Kantox.Offer{
      id: id,
      fun: fun
    }
  end

  def all() do
    [
      new("GR1", fn qty, product ->
        paid_qty = div(qty + 1, 2)
        Decimal.mult(product.price, paid_qty)
      end),
      new("SR1", fn qty, product ->
        if qty >= 3 do
          Decimal.mult(Decimal.new("4.50"), qty)
        else
          Decimal.mult(product.price, qty)
        end
      end),
      new("CF1", fn qty, product ->
        if qty >= 3 do
          Decimal.mult(
            product.price,
            Decimal.mult(Decimal.new(qty), Decimal.div(Decimal.new(2), Decimal.new(3)))
          )
        else
          Decimal.mult(product.price, qty)
        end
      end)
    ]
  end
end
