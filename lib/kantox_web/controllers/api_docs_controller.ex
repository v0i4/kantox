defmodule KantoxWeb.ApiDocsController do
  use KantoxWeb, :controller

  def openapi(conn, _params) do
    json_path = Path.join(:code.priv_dir(:kantox), "static/openapi.json")

    conn
    |> put_resp_content_type("application/json")
    |> send_file(200, json_path)
  end
end

