defmodule KantoxWeb.OfferController do
  use KantoxWeb, :controller

  def index(conn, _params) do
    offers = Kantox.Offers.all()
    render(conn, "index.json", %{offers: offers})
  end

  def create(conn, %{"offer" => offer_params}) do
    with {:ok, offer} <- Kantox.Offers.create(offer_params) do
      conn
      |> put_status(:created)
      |> json(KantoxWeb.OfferJSON.data(offer))
    else
      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> json(KantoxWeb.OfferJSON.error(%{changeset: changeset}))
    end
  end
end
