defmodule Trenurang.Repo.Migrations.AddHalfLifeOverridesToCategories do
  use Ecto.Migration

  def change do
    alter table(:categories) do
      add :geo_half_life_km, :float
      add :recency_half_life_days, :float
    end
  end
end
