defmodule Kantox.Repo.Migrations.AddIndexesToOffers do
  use Ecto.Migration

  def change do
    # This index covers the most common query in basket processing:
    # WHERE product_code = ? AND active = ? AND starts_at < ? AND ends_at > ?
    # Expected impact: 10-100x faster offer lookups
    create index(:offers, [:product_code, :active, :starts_at, :ends_at],
      name: :offers_product_active_dates_index
    )

    # Index on product_code alone (for admin/reporting queries)
    # Used when fetching all offers for a specific product
    # Also useful for future foreign key constraint
    create index(:offers, [:product_code],
      name: :offers_product_code_index
    )

    # Partial index for active offers only (optimization)
    # Only indexes rows where active = true
    # Benefits: Smaller index, faster queries, less maintenance
    # Expected impact: 50-90% smaller index size
    create index(:offers, [:product_code, :starts_at, :ends_at],
      where: "active = true",
      name: :offers_active_lookup_index
    )

    # 4. Index for date range queries (cache refresh scenarios)
    # Used when fetching offers by date range
    # Useful for reporting and scheduled tasks
    create index(:offers, [:starts_at, :ends_at],
      name: :offers_date_range_index
    )
  end
end
