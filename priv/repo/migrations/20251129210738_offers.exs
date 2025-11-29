defmodule Kantox.Repo.Migrations.Offers do
  use Ecto.Migration

  def change do
    create table(:offers) do
      add :product_code, :string
      add :offer_type, :string
      add :params, :map
      add :active, :boolean
      add :starts_at, :utc_datetime
      add :ends_at, :utc_datetime
      timestamps()
    end
  end
end
