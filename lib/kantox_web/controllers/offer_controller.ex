defmodule KantoxWeb.OfferController do
  use KantoxWeb, :controller

  def index(conn, _params) do
    offers = Kantox.Offers.all()
    render(conn, "index.json", %{offers: offers})
  end
end
