defmodule Kantox.Offers do
  alias Kantox.Offer
  alias Kantox.Repo

  def all() do
    Repo.all(Offer)
  end

  def create(attrs \\ %{}) do
    %Offer{}
    |> Offer.changeset(attrs)
    |> Repo.insert()
  end
end
