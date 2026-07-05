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

  @doc """
  Cosine similarity antar dua embedding vector.
  Kalau salah satu (atau keduanya) nil -> netral 0.5. Ini mencakup dua kasus
  sekaligus tanpa Scoring perlu tahu alasannya: privacy mode (embedding_private)
  ATAU semua provider FallbackChain gagal (caller menerjemahkan error jadi nil
  sebelum masuk sini -- Decision Log #55, pemisahan concern).
  """
  @spec semantic_similarity([float()] | nil, [float()] | nil) :: float()
  def semantic_similarity(nil, _), do: 0.5
  def semantic_similarity(_, nil), do: 0.5

  def semantic_similarity(a, b) when is_list(a) and is_list(b) do
    if length(a) != length(b) do
      raise ArgumentError,
            "embedding vector harus sama panjang, dapat #{length(a)} vs #{length(b)} -- " <>
              "model embedding harus seragam di level platform (Decision Log #49)"
    end

    dot = dot_product(a, b)
    norm_a = magnitude(a)
    norm_b = magnitude(b)

    if norm_a == 0.0 or norm_b == 0.0 do
      0.5
    else
      dot / (norm_a * norm_b)
    end
  end

  defp dot_product(a, b) do
    Enum.zip(a, b)
    |> Enum.reduce(0.0, fn {x, y}, acc -> acc + x * y end)
  end

  defp magnitude(vector) do
    vector
    |> Enum.reduce(0.0, fn x, acc -> acc + x * x end)
    |> :math.sqrt()
  end

  defp compare_dimension(nil, _), do: 0.5
  defp compare_dimension(_, nil), do: 0.5
  defp compare_dimension(same, same), do: 1.0
  defp compare_dimension(_, _), do: 0.0
end
