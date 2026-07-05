defmodule Trenurang.Matching.Scoring do
  @moduledoc """
  5-signal weighted scoring function untuk menghitung kecocokan antar dua Intent.
  Bukan ML -- multi-factor weighted formula yang explainable, langsung buildable,
  sekaligus mengumpulkan score_breakdown sebagai dataset latih ML v2 (§7 ARCHITECTURE.md).

  actor_signal placeholder konstan 1.0 di MVP (Decision Log #20).
  """

  alias Trenurang.Matching.DimensionProfile

  @doc """
  Rata-rata kecocokan ke-9 dimensi antar dua DimensionProfile.
  Per-dimensi: sama & non-nil -> 1.0, beda & non-nil -> 0.0, salah satu nil -> 0.5.
  """
  @spec dimension_match(DimensionProfile.t(), DimensionProfile.t()) :: float()
  def dimension_match(%DimensionProfile{} = a, %DimensionProfile{} = b) do
    dimensions = [
      :cardinality,
      :divisibility,
      :resolution_mode,
      :temporality,
      :spatiality,
      :exchange_form,
      :visibility,
      :trust_level,
      :urgency
    ]

    scores =
      Enum.map(dimensions, fn dim ->
        compare_dimension(Map.get(a, dim), Map.get(b, dim))
      end)

    Enum.sum(scores) / length(scores)
  end

  defp compare_dimension(nil, _), do: 0.5
  defp compare_dimension(_, nil), do: 0.5
  defp compare_dimension(same, same), do: 1.0
  defp compare_dimension(_, _), do: 0.0
end
