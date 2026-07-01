defmodule Trenurang.Matching.Router do
  @moduledoc """
  Memilih pola matching berdasarkan 3 dimensi penentu topologi:
  cardinality, resolution_mode, divisibility.

  6 dimensi sisanya (temporality, spatiality, exchange_form, visibility,
  trust_level, urgency) mengubah PERILAKU pipeline via pipeline_modifiers/1,
  bukan topologi algoritmanya.
  """

  alias Trenurang.Matching.DimensionProfile

  @type pattern ::
    :similarity_geospatial
    | :auction
    | :stable_matching_1to1
    | :stable_matching_many_to_1
    | :aggregation_pooling
    | :negotiation_flow

  @doc """
  Memilih pola matching berdasarkan cardinality, resolution_mode, divisibility.
  Urutan klausa penting -- :price_discovery selalu menang karena mekanisme
  lelang tidak peduli cardinality atau divisibility.
  """
  @spec select_pattern(DimensionProfile.t()) :: pattern()
  def select_pattern(%DimensionProfile{} = p) do
    case {p.cardinality, p.resolution_mode, p.divisibility} do
      {_, :price_discovery, _}             -> :auction
      {:one_to_one, :exact_preference, _}  -> :stable_matching_1to1
      {:many_to_one, :exact_preference, _} -> :stable_matching_many_to_1
      {:many_to_one, _, :divisible}        -> :aggregation_pooling
      {_, :negotiated, _}                  -> :negotiation_flow
      {_, :fuzzy_score, _}                 -> :similarity_geospatial
      _                                    -> :similarity_geospatial
    end
  end

  @doc """
  Memvalidasi kombinasi dimensi. Menolak tepat satu kombinasi yang tidak
  memiliki algoritma settled: :many_to_many + :exact_preference.
  Semua kombinasi lain diizinkan, termasuk :one_to_one + :divisible
  yang secara konsep valid (Decision Log #44, #45).
  """
  @spec validate_combination(DimensionProfile.t()) :: :ok | {:error, String.t()}
  def validate_combination(%DimensionProfile{} = p) do
    case {p.cardinality, p.resolution_mode} do
      {:many_to_many, :exact_preference} ->
        {:error,
         "kombinasi :many_to_many + :exact_preference tidak didukung: " <>
           "tidak ada algoritma stable matching yang menjamin hasil untuk banyak-ke-banyak " <>
           "dengan preferensi eksplisit"}

      _ ->
        :ok
    end
  end

  @doc """
  Menghasilkan map modifier yang mengubah perilaku pipeline matching,
  berdasarkan 6 dimensi non-topologi.
  """
  @spec pipeline_modifiers(DimensionProfile.t()) :: map()
  def pipeline_modifiers(%DimensionProfile{} = p) do
    %{
      skip_geo_filter?: p.spatiality == :remote,
      requires_verification_gate?: p.trust_level == :verified_required,
      mask_identity_until_match?: p.visibility == :anonymous_until_match,
      notification_sla:
        case p.urgency do
          :emergency -> :immediate
          :urgent    -> :fast
          _          -> :batched
        end
    }
  end
end
