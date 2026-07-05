defmodule Trenurang.Matching.ScoringTest do
  use ExUnit.Case, async: true

  alias Trenurang.Matching.{DimensionProfile, Scoring}

  # Helper sama seperti router_test.exs -- default profile yang bisa di-override
  defp profile(overrides) do
    defaults = %{
      cardinality: :one_to_one,
      divisibility: :indivisible,
      resolution_mode: :fuzzy_score,
      temporality: :one_time,
      spatiality: :location_bound,
      exchange_form: :monetary,
      visibility: :public,
      trust_level: :open,
      urgency: :normal
    }

    struct!(DimensionProfile, Map.merge(defaults, overrides))
  end

  describe "dimension_match/2" do
    test "profile identik -> 1.0" do
      p = profile(%{})
      assert Scoring.dimension_match(p, p) == 1.0
    end

    test "semua 9 dimensi berbeda -> 0.0" do
      a =
        profile(%{
          cardinality: :one_to_one,
          divisibility: :indivisible,
          resolution_mode: :fuzzy_score,
          temporality: :one_time,
          spatiality: :location_bound,
          exchange_form: :monetary,
          visibility: :public,
          trust_level: :open,
          urgency: :normal
        })

      b =
        profile(%{
          cardinality: :many_to_one,
          divisibility: :divisible,
          resolution_mode: :negotiated,
          temporality: :recurring,
          spatiality: :remote,
          exchange_form: :barter,
          visibility: :private,
          trust_level: :verified_required,
          urgency: :urgent
        })

      assert Scoring.dimension_match(a, b) == 0.0
    end

    test "satu dimensi beda dari 9 -> (8*1.0 + 1*0.0)/9" do
      a = profile(%{})
      b = profile(%{urgency: :emergency})

      assert_in_delta Scoring.dimension_match(a, b), 8 / 9, 0.0001
    end

    test "salah satu field nil -> dimensi itu netral 0.5" do
      a = profile(%{urgency: nil})
      b = profile(%{urgency: :urgent})

      # 8 dimensi sama (1.0) + 1 dimensi nil (0.5) => (8 + 0.5) / 9
      assert_in_delta Scoring.dimension_match(a, b), 8.5 / 9, 0.0001
    end

    test "kedua field nil di dimensi yang sama -> netral 0.5, bukan 1.0" do
      a = profile(%{urgency: nil})
      b = profile(%{urgency: nil})

      assert_in_delta Scoring.dimension_match(a, b), 8.5 / 9, 0.0001
    end
  end

  describe "semantic_similarity/2" do
    test "embedding_a nil -> netral 0.5" do
      assert Scoring.semantic_similarity(nil, [1.0, 0.0]) == 0.5
    end

    test "embedding_b nil -> netral 0.5" do
      assert Scoring.semantic_similarity([1.0, 0.0], nil) == 0.5
    end

    test "keduanya nil -> netral 0.5" do
      assert Scoring.semantic_similarity(nil, nil) == 0.5
    end

    test "vector identik -> 1.0" do
      v = [1.0, 2.0, 3.0]
      assert_in_delta Scoring.semantic_similarity(v, v), 1.0, 0.0001
    end

    test "vector berlawanan arah -> -1.0" do
      a = [1.0, 0.0]
      b = [-1.0, 0.0]
      assert_in_delta Scoring.semantic_similarity(a, b), -1.0, 0.0001
    end

    test "vector orthogonal -> 0.0" do
      a = [1.0, 0.0]
      b = [0.0, 1.0]
      assert_in_delta Scoring.semantic_similarity(a, b), 0.0, 0.0001
    end

    test "panjang vector beda -> raise ArgumentError" do
      assert_raise ArgumentError, fn ->
        Scoring.semantic_similarity([1.0, 2.0], [1.0])
      end
    end

    test "salah satu vector nol semua -> netral 0.5, bukan crash" do
      assert Scoring.semantic_similarity([0.0, 0.0], [1.0, 2.0]) == 0.5
    end
  end

  describe "geo_proximity/3" do
    test "titik sama -> distance 0 -> score 1.0, apapun half_life" do
      point = {106.8, -6.2}
      assert_in_delta Scoring.geo_proximity(point, point, 10.0), 1.0, 0.0001
    end

    test "jarak sama dengan half_life_km -> score 0.5" do
      # 1 derajat latitude di ekuator ~ 111.19 km (radius bumi 6371km * pi/180)
      point_a = {0.0, 0.0}
      point_b = {0.0, 1.0}
      half_life_km = 111.19

      assert_in_delta Scoring.geo_proximity(point_a, point_b, half_life_km), 0.5, 0.01
    end

    test "jarak 2x half_life -> score 0.25 (0.5^2)" do
      point_a = {0.0, 0.0}
      point_b = {0.0, 1.0}
      # jarak ~111.19km, half_life setengahnya -> distance/half_life = 2
      half_life_km = 111.19 / 2

      assert_in_delta Scoring.geo_proximity(point_a, point_b, half_life_km), 0.25, 0.01
    end

    test "jarak jauh (quarter keliling bumi di ekuator, ~10007km) -> score mendekati 0" do
      point_a = {0.0, 0.0}
      point_b = {90.0, 0.0}
      half_life_km = 10.0

      score = Scoring.geo_proximity(point_a, point_b, half_life_km)
      assert score < 0.0001
      assert score > 0.0
    end

    test "half_life_km <= 0 -> raise ArgumentError" do
      point = {0.0, 0.0}

      assert_raise ArgumentError, fn ->
        Scoring.geo_proximity(point, point, 0)
      end

      assert_raise ArgumentError, fn ->
        Scoring.geo_proximity(point, point, -5.0)
      end
    end
  end

  describe "recency/3" do
    test "waktu sama -> score 1.0" do
      now = DateTime.utc_now()
      assert_in_delta Scoring.recency(now, now, 7.0), 1.0, 0.0001
    end

    test "selisih sama dengan half_life_days -> score 0.5" do
      time_a = ~U[2026-07-05 00:00:00Z]
      time_b = ~U[2026-07-12 00:00:00Z]

      assert_in_delta Scoring.recency(time_a, time_b, 7.0), 0.5, 0.0001
    end

    test "urutan argumen tidak masalah -- selisih dihitung absolut" do
      time_a = ~U[2026-07-05 00:00:00Z]
      time_b = ~U[2026-07-12 00:00:00Z]

      score_forward = Scoring.recency(time_a, time_b, 7.0)
      score_backward = Scoring.recency(time_b, time_a, 7.0)

      assert_in_delta score_forward, score_backward, 0.0001
    end

    test "selisih 2x half_life -> score 0.25" do
      time_a = ~U[2026-07-05 00:00:00Z]
      time_b = ~U[2026-07-19 00:00:00Z]

      assert_in_delta Scoring.recency(time_a, time_b, 7.0), 0.25, 0.0001
    end

    test "half_life_days <= 0 -> raise ArgumentError" do
      now = DateTime.utc_now()

      assert_raise ArgumentError, fn ->
        Scoring.recency(now, now, 0)
      end

      assert_raise ArgumentError, fn ->
        Scoring.recency(now, now, -3.0)
      end
    end
  end
end
