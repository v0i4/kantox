defmodule Kantox.Cache.OffersCache do
  @moduledoc """
  Offers-specific cache layer using ETS.
  Provides high-performance, concurrent access to offers.
  """

  alias Kantox.Cache.ETSCache
  alias Kantox.Offers

  require Logger

  @cache_key :active_offers
  @ttl :timer.minutes(15)

  @doc """
  Gets all active offers from cache.
  If cache is empty or expired, loads from database.
  """
  def get_offers do
    case ETSCache.get(@cache_key) do
      nil ->
        refresh_offers()

      offers ->
        offers
    end
  end

  @doc """
  Refreshes offers cache from database.
  Returns the updated list of offers.
  """
  def refresh_offers do
    Logger.debug("Refreshing offers cache from database")

    offers = Offers.all()
    ETSCache.put(@cache_key, offers, @ttl)

    offers
  end

  @doc """
  Invalidates the offers cache.
  Next call to get_offers will reload from database.
  """
  def invalidate do
    Logger.debug("Invalidating offers cache")
    ETSCache.delete(@cache_key)
  end

  @doc """
  Gets a specific offer by product code from cache.
  """
  def get_offer_by_product_code(product_code) do
    get_offers()
    |> Enum.find(&(&1.product_code == product_code))
  end

  @doc """
  Gets all active offers for a product code from cache.
  """
  def get_active_offers_for_product(product_code) do
    now = DateTime.utc_now()

    get_offers()
    |> Enum.filter(fn offer ->
      offer.product_code == product_code and
        offer.active and
        DateTime.compare(offer.starts_at, now) in [:lt, :eq] and
        DateTime.compare(offer.ends_at, now) in [:gt, :eq]
    end)
  end
end

