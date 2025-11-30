defmodule KantoxWeb.BasketView do
  def render("index.json", %{total: total}) do
    %{total: total}
  end
end
