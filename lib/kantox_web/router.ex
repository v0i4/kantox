defmodule KantoxWeb.Router do
  use KantoxWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", KantoxWeb do
    pipe_through :api

    get "/health", HealthController, :index
    get "/offers", OfferController, :index
    get "/products", ProductController, :index
    post "/baskets", BasketController, :process
    post "/products", ProductController, :create
    post "/offers", OfferController, :create
  end

  # Catch-all route for root
  scope "/", KantoxWeb do
    pipe_through :api

    get "/", HealthController, :index
  end
end
