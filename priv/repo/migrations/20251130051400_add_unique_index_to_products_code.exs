defmodule Kantox.Repo.Migrations.AddUniqueIndexToProductsCode do
  use Ecto.Migration

  def up do
    # Remove duplicate products, keeping only the one with lowest ID for each code
    execute """
    DELETE FROM products
    WHERE id NOT IN (
      SELECT MIN(id)
      FROM products
      GROUP BY code
    )
    """

    # Now add the unique index
    create unique_index(:products, [:code])
  end

  def down do
    drop index(:products, [:code])
  end
end
