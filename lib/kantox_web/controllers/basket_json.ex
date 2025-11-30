defmodule KantoxWeb.BasketJSON do
  @doc """
  Renders the basket processing result.
  """
  def index(%{result: result, status: status}) do
    %{
      total: result.total,
      full_price: result.full_price,
      off_price: result.off_price,
      status: status
    }
  end
end
