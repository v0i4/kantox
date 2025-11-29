defmodule KantoxWeb.Router do
  use KantoxWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", KantoxWeb do
    pipe_through :api

    # Add your API routes here
  end
end
