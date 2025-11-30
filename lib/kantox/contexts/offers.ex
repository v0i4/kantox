defmodule Kantox.Offers do
  alias Kantox.Offer
  alias Kantox.Repo
  alias Kantox.OffersCache

  def all() do
    Offer
    |> Repo.all()
    |> Enum.uniq()
  end

  def create(attrs \\ %{}) do
    with {:ok, offer} <-
           %Offer{}
           |> Offer.changeset(attrs)
           |> Repo.insert() do
      OffersCache.update_offers(offer)

      {:ok, offer}
    else
      {:error, changeset} -> {:error, changeset}
    end
  end
end
