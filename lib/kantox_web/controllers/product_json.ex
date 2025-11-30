defmodule KantoxWeb.ProductJSON do
  @doc """
  Renders a list of products.
  """
  def index(%{products: products}) do
    %{
      data: for(product <- products, do: data(product)),
      count: length(products)
    }
  end

  @doc """
  Renders a single product.
  """
  def data(%{id: id, name: name, code: code, price: price}) do
    %{
      id: id,
      name: name,
      code: code,
      price: price
    }
  end

  @doc """
  Renders errors.
  """
  def error(%{changeset: changeset}) do
    %{
      errors: Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
    }
  end

  defp translate_error({msg, opts}) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      String.replace(acc, "%{#{key}}", to_string(value))
    end)
  end
end
