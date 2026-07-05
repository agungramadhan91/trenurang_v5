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
end
