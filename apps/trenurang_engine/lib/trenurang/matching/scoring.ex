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

  @earth_radius_km 6371.0

  @doc """
  Half-life decay berbasis jarak Haversine antar dua titik {lng, lat}.
  score = 0.5^(distance_km / half_life_km) -- di jarak = half_life_km, score = 0.5.

  CATATAN: fungsi ini TIDAK mengecek spatiality. Kalau Intent bersifat :remote
  (skip_geo_filter? dari Router.pipeline_modifiers/1), caller (context Matching,
  fase berikutnya) yang bertanggung jawab tidak memanggil fungsi ini sama sekali
  dan pakai netral 0.5 langsung -- bukan tanggung jawab Scoring.geo_proximity/3
  untuk tahu soal itu.
  """
  @spec geo_proximity({number(), number()}, {number(), number()}, number()) :: float()
  def geo_proximity(_point_a, _point_b, half_life_km) when half_life_km <= 0 do
    raise ArgumentError, "half_life_km harus > 0, dapat #{half_life_km}"
  end

  def geo_proximity({lng_a, lat_a}, {lng_b, lat_b}, half_life_km) do
    distance_km = haversine_km(lng_a, lat_a, lng_b, lat_b)
    :math.pow(0.5, distance_km / half_life_km)
  end

  @doc """
  Half-life decay berbasis selisih waktu (recency) antar dua Intent.
  score = 0.5^(days_diff / half_life_days) -- di selisih = half_life_days, score = 0.5.
  Selisih dihitung absolut -- Intent lebih baru atau lebih lama dari pembanding
  diperlakukan sama (recency bukan soal urutan, cuma soal jarak waktu).
  """
  @spec recency(DateTime.t(), DateTime.t(), number()) :: float()
  def recency(_time_a, _time_b, half_life_days) when half_life_days <= 0 do
    raise ArgumentError, "half_life_days harus > 0, dapat #{half_life_days}"
  end

  def recency(%DateTime{} = time_a, %DateTime{} = time_b, half_life_days) do
    diff_seconds = DateTime.diff(time_a, time_b, :second) |> abs()
    diff_days = diff_seconds / 86_400

    :math.pow(0.5, diff_days / half_life_days)
  end

  defp haversine_km(lng_a, lat_a, lng_b, lat_b) do
    lat_a_rad = deg_to_rad(lat_a)
    lat_b_rad = deg_to_rad(lat_b)
    delta_lat = deg_to_rad(lat_b - lat_a)
    delta_lng = deg_to_rad(lng_b - lng_a)

    a =
      :math.pow(:math.sin(delta_lat / 2), 2) +
        :math.cos(lat_a_rad) * :math.cos(lat_b_rad) * :math.pow(:math.sin(delta_lng / 2), 2)

    c = 2 * :math.asin(:math.sqrt(a))

    @earth_radius_km * c
  end

  defp deg_to_rad(deg), do: deg * :math.pi() / 180

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
