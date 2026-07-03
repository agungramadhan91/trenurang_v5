defmodule Trenurang.Catalog.Taxonomy do
  @moduledoc """
  resolve_effective_profile/2 -- hitung dimension_profile efektif dari
  hierarki Category dengan nil-inheritance (cascading mirip CSS): override
  di child menang, field nil di child diwarisi parent, naik sampai root.
  """

  alias Trenurang.Catalog.Category
  alias Trenurang.Repo

  @spec resolve_effective_profile(Category.t(), map()) :: map()
  def resolve_effective_profile(%Category{} = category, explicit_overrides \\ %{}) do
    category
    |> ancestor_chain()
    |> Enum.reverse()
    |> Enum.reduce(%{}, fn cat, acc ->
      Map.merge(acc, cat.dimension_profile_overrides || %{}, fn _k, _old, new -> new end)
    end)
    |> Map.merge(explicit_overrides, fn _k, _old, new -> new end)
  end

  @spec resolve_effective_weights(Category.t()) :: map()
  def resolve_effective_weights(%Category{} = category) do
    category
    |> ancestor_chain()
    |> Enum.reverse()
    |> Enum.reduce(%{}, fn cat, acc ->
      Map.merge(acc, cat.scoring_weight_overrides || %{}, fn _k, _old, new -> new end)
    end)
  end

  # Default platform kalau seluruh ancestor chain tidak mengisi override.
  # Nilai ini BUKAN keputusan final bisnis -- cuma starting point aman,
  # bisa direvisit per kategori lewat geo_half_life_km/recency_half_life_days.
  @default_geo_half_life_km 10.0
  @default_recency_half_life_days 7.0

  @spec resolve_effective_half_life(Category.t()) :: %{
          geo_half_life_km: float(),
          recency_half_life_days: float()
        }
  def resolve_effective_half_life(%Category{} = category) do
    chain = ancestor_chain(category)

    %{
      geo_half_life_km:
        find_first_non_nil(chain, & &1.geo_half_life_km) || @default_geo_half_life_km,
      recency_half_life_days:
        find_first_non_nil(chain, & &1.recency_half_life_days) || @default_recency_half_life_days
    }
  end

  defp find_first_non_nil(chain, field_fn) do
    Enum.find_value(chain, fn cat -> field_fn.(cat) end)
  end

  defp ancestor_chain(%Category{parent_id: nil} = category), do: [category]

  defp ancestor_chain(%Category{} = category) do
    case Repo.get(Category, category.parent_id) do
      nil -> [category]
      parent -> [category | ancestor_chain(parent)]
    end
  end
end
