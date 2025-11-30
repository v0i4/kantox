defmodule KantoxWeb.Router do
  use KantoxWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_rate_limited do
    plug :accepts, ["json"]
    plug KantoxWeb.Plugs.RateLimiter
  end

  # API Documentation - serves openapi.json
  scope "/api", KantoxWeb do
    pipe_through :api
    get "/openapi", ApiDocsController, :openapi
  end

  # Swagger UI
  scope "/api/swagger" do
    forward "/", PhoenixSwagger.Plug.SwaggerUI,
      otp_app: :kantox,
      swagger_file: "openapi.json"
  end

  scope "/api", KantoxWeb do
    pipe_through :api

    get "/health", HealthController, :index
    get "/offers", OfferController, :index
    get "/products", ProductController, :index
  end

  # Rate-limited endpoints
  scope "/api", KantoxWeb do
    pipe_through :api_rate_limited

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
