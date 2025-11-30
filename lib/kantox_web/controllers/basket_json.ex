defmodule KantoxWeb.BasketJSON do
  @doc """
  Renders the basket processing result.
  """
  def index(%{total: total, status: status}) do
    %{
      total: total,
      status: status
    }
  end
end
