defmodule Trenurang.Matching.Intent do
  @moduledoc """
  Intent = satu pernyataan supply ATAU demand. `dimension_profile` adalah
  SNAPSHOT saat dibuat, BUKAN referensi ke Category -- supaya perubahan
  Category di kemudian hari tidak mengubah Intent yang sudah ada secara
  retroaktif. `direction` properti Intent, bukan properti source-nya.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "intents" do
    field :direction, Ecto.Enum, values: [:supply, :demand]
    # polymorphic -- "Profile" | "Product" | "Program"
    field :source_type, :string
    field :source_id, :binary_id
    field :dimension_profile, :map, default: %{}
    field :geo_point, Geo.PostGIS.Geometry
    field :embedding, {:array, :float}
    field :status, Ecto.Enum, values: [:active, :matched, :closed], default: :active

    belongs_to :actor, Trenurang.Accounts.Actor
    belongs_to :category, Trenurang.Catalog.Category

    timestamps()
  end

  @type t :: %__MODULE__{}

  def changeset(intent, attrs) do
    intent
    |> cast(attrs, [
      :direction,
      :source_type,
      :source_id,
      :actor_id,
      :category_id,
      :dimension_profile,
      :geo_point,
      :embedding,
      :status
    ])
    |> validate_required([:direction, :source_type, :source_id, :actor_id, :category_id, :dimension_profile])
    |> validate_inclusion(:source_type, ["Profile", "Product", "Program"])
  end
end
