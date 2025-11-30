defmodule Kantox.OffersCache do
  use GenServer
  alias Kantox.Offers

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, Offers.all()}
  end

  def get_offers() do
    GenServer.call(__MODULE__, :get_offers)
  end

  def handle_call(:get_offers, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:update_offers, offer}, _from, state) do
    {:reply, :ok, [offer | state]}
  end

  def handle_call(:refresh, _from, _state) do
    new_state = Offers.all()
    {:reply, :ok, new_state}
  end

  def update_offers(new_offer) do
    GenServer.call(__MODULE__, {:update_offers, new_offer})
  end

  def refresh() do
    GenServer.call(__MODULE__, :refresh)
  end
end
