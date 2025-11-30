defmodule Kantox.ProductsCache do
  use GenServer
  alias Kantox.Products

  def start_link(_args) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, Products.get_all_product_codes()}
  end

  def get_all_product_codes() do
    GenServer.call(__MODULE__, :get_all_product_codes)
  end

  def handle_call(:get_all_product_codes, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:update_products, product}, _from, state) do
    {:reply, :ok, [product | state]}
  end

  def update_products(new_product_code) do
    GenServer.call(__MODULE__, {:update_products, new_product_code})
  end
end
