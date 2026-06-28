defmodule Trenurang.Repo.Migrations.CreateCoreSchema do
  use Ecto.Migration

  def change do
    execute("CREATE EXTENSION IF NOT EXISTS postgis", "DROP EXTENSION IF EXISTS postgis")

    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :active_actor_id, :binary_id
      timestamps()
    end

    create table(:channel_identities, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :channel, :string, null: false
      add :channel_user_id, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      timestamps()
    end

    create unique_index(:channel_identities, [:channel, :channel_user_id])
    create index(:channel_identities, [:user_id])

    create table(:actors, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :type, :string, null: false
      add :legal_form, :string
      add :mandate_type, :string
      add :display_name, :string, null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:actors, [:user_id])

    create table(:categories, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :is_active, :boolean, default: false, null: false
      add :dimension_profile_overrides, :map, default: %{}
      add :scoring_weight_overrides, :map, default: %{}
      add :permitted_filter_dimensions, {:array, :string}, default: []
      add :regulatory_domain, :string
      add :required_actor_fields_for_category, {:array, :string}, default: []
      add :parent_id, references(:categories, type: :binary_id, on_delete: :nilify_all)
      timestamps()
    end

    create index(:categories, [:parent_id])

    create table(:personas, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :display_name, :string
      add :skills, {:array, :string}, default: []
      add :description, :text
      add :actor_id, references(:actors, type: :binary_id, on_delete: :delete_all), null: false
      timestamps()
    end

    create index(:personas, [:actor_id])

    create table(:produks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :description, :text
      add :unit_price, :decimal
      add :stock_quantity, :integer
      add :actor_id, references(:actors, type: :binary_id, on_delete: :delete_all), null: false
      add :category_id, references(:categories, type: :binary_id, on_delete: :restrict), null: false
      timestamps()
    end

    create index(:produks, [:actor_id])
    create index(:produks, [:category_id])

    create table(:agenda_programs, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :description, :text
      add :starts_at, :utc_datetime
      add :ends_at, :utc_datetime
      add :capacity, :integer
      add :actor_id, references(:actors, type: :binary_id, on_delete: :delete_all), null: false
      add :category_id, references(:categories, type: :binary_id, on_delete: :restrict), null: false
      timestamps()
    end

    create index(:agenda_programs, [:actor_id])
    create index(:agenda_programs, [:category_id])

    create table(:intents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :direction, :string, null: false
      add :source_type, :string, null: false
      add :source_id, :binary_id, null: false
      add :dimension_profile, :map, null: false, default: %{}
      add :geo_point, :"geometry(Point,4326)"
      add :embedding, {:array, :float}
      add :status, :string, default: "active", null: false
      add :actor_id, references(:actors, type: :binary_id, on_delete: :delete_all), null: false
      add :category_id, references(:categories, type: :binary_id, on_delete: :restrict), null: false
      timestamps()
    end

    create index(:intents, [:category_id, :direction, :status])
    create index(:intents, [:actor_id])
  end
end
