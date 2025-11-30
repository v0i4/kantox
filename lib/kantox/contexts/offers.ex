defmodule Kantox.Offers do
  @moduledoc """
  Context for managing promotional offers.
  Uses ETS-based caching for high performance.
  """

  alias Kantox.Offer
  alias Kantox.Repo
  alias Kantox.Cache.OffersCache

  require Logger

  @doc """
  Returns all offers from the database.
  """
  def all do
    Offer
    |> Repo.all()
  end

  @doc """
  Creates a new offer and invalidates the cache.
  """
  def create(attrs \\ %{}) do
    with {:ok, offer} <-
           %Offer{}
           |> Offer.changeset(attrs)
           |> Repo.insert() do
      # Invalidate cache so next request fetches fresh data
      OffersCache.invalidate()
      Logger.info("Created offer #{offer.id} and invalidated cache")

      {:ok, offer}
    else
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Gets active offers for a specific product code.
  """
  def get_active_for_product(product_code) do
    OffersCache.get_active_offers_for_product(product_code)
  end
end
