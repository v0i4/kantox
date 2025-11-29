defmodule Kantox.Repo.Migrations.Products do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :code, :string
      add :price, :float
      timestamps()
    end
  end
end
