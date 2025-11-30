defmodule KantoxWeb.HealthController do
  use KantoxWeb, :controller

  def index(conn, _params) do
    json(conn, %{
      status: "ok",
      service: "Kantox API",
      timestamp: DateTime.utc_now()
    })
  end
end
