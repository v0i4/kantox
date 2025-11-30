defmodule KantoxWeb.OfferJSON do
  @doc """
  Renders a list of offers.
  """
  def index(%{offers: offers}) do
    %{
      data: for(offer <- offers, do: data(offer)),
      count: length(offers)
    }
  end

  @doc """
  Renders a single offer.
  """
  def data(%{
        id: id,
        product_code: product_code,
        offer_type: offer_type,
        params: params,
        active: active,
        starts_at: starts_at,
        ends_at: ends_at
      }) do
    %{
      id: id,
      product_code: product_code,
      offer_type: offer_type,
      params: params,
      active: active,
      starts_at: starts_at,
      ends_at: ends_at
    }
  end
end
