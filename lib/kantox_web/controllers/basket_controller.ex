defmodule KantoxWeb.BasketController do
  use KantoxWeb, :controller

  def process(conn, %{"basket" => basket}) do
    with {:ok, result} <- Kantox.CashierService.process(basket) do
      render(conn, "index.json", %{result: result, status: "success"})
    else
      {:error, message} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: message})
    end
  end
end
