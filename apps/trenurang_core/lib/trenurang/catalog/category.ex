defmodule Trenurang.Catalog.Category do
  @moduledoc """
  Tree hierarki via parent_id. `dimension_profile_overrides` &
  `scoring_weight_overrides` di-resolve nil-inheritance lewat
  Trenurang.Catalog.Taxonomy (cascading mirip CSS).

  `permitted_filter_dimensions` -- whitelist dimensi demografis yang
  boleh jadi hard filter (kontrol legal).
  `regulatory_domain` -- nil kalau tidak teregulasi; kalau terisi,
  kategori butuh aktivasi manual (`is_active`) -- compliance gate
  terjadi di aktivasi kategori, BUKAN per-Intent.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "categories" do
    field :name, :string
    field :is_active, :boolean, default: false
    field :dimension_profile_overrides, :map, default: %{}
    field :scoring_weight_overrides, :map, default: %{}
    field :permitted_filter_dimensions, {:array, :string}, default: []
    field :regulatory_domain, Ecto.Enum,
      values: [:age_restricted, :health_product, :financial_service, :employment]
    field :required_actor_fields_for_category, {:array, :string}, default: []

    belongs_to :parent, __MODULE__
    has_many :children, __MODULE__, foreign_key: :parent_id

    timestamps()
  end

  @type t :: %__MODULE__{}

  def changeset(category, attrs) do
    category
    |> cast(attrs, [
      :name,
      :parent_id,
      :is_active,
      :dimension_profile_overrides,
      :scoring_weight_overrides,
      :permitted_filter_dimensions,
      :regulatory_domain,
      :required_actor_fields_for_category
    ])
    |> validate_required([:name])
    |> foreign_key_constraint(:parent_id, message: "kategori induk tidak ditemukan")
  end
end
