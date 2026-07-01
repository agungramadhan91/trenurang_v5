defmodule Trenurang.Matching.RouterTest do
  use ExUnit.Case, async: true

  alias Trenurang.Matching.{DimensionProfile, Router}

  # Helper: buat DimensionProfile dengan nilai default yang bisa di-override
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

    merged = Map.merge(defaults, overrides)

    struct!(DimensionProfile, merged)
  end

  # ──────────────────────────────────────────
  # select_pattern/1
  # ──────────────────────────────────────────

  describe "select_pattern/1 - penentu topologi" do
    test ":price_discovery selalu menghasilkan :auction, apapun cardinality & divisibility" do
      assert Router.select_pattern(profile(%{resolution_mode: :price_discovery, cardinality: :one_to_one})) == :auction
      assert Router.select_pattern(profile(%{resolution_mode: :price_discovery, cardinality: :many_to_one})) == :auction
      assert Router.select_pattern(profile(%{resolution_mode: :price_discovery, cardinality: :many_to_many})) == :auction
    end

    test ":one_to_one + :exact_preference -> :stable_matching_1to1" do
      assert Router.select_pattern(profile(%{cardinality: :one_to_one, resolution_mode: :exact_preference})) ==
               :stable_matching_1to1
    end

    test ":many_to_one + :exact_preference -> :stable_matching_many_to_1" do
      assert Router.select_pattern(profile(%{cardinality: :many_to_one, resolution_mode: :exact_preference})) ==
               :stable_matching_many_to_1
    end

    test ":many_to_one + :divisible (bukan :exact_preference) -> :aggregation_pooling" do
      assert Router.select_pattern(profile(%{cardinality: :many_to_one, divisibility: :divisible, resolution_mode: :fuzzy_score})) ==
               :aggregation_pooling
    end

    test ":negotiated -> :negotiation_flow" do
      assert Router.select_pattern(profile(%{resolution_mode: :negotiated})) == :negotiation_flow
    end

    test ":fuzzy_score -> :similarity_geospatial (default MVP)" do
      assert Router.select_pattern(profile(%{resolution_mode: :fuzzy_score})) == :similarity_geospatial
    end

    test "fallback aman: :many_to_many + :fuzzy_score -> :similarity_geospatial" do
      assert Router.select_pattern(profile(%{cardinality: :many_to_many, resolution_mode: :fuzzy_score})) ==
               :similarity_geospatial
    end
  end

  # ──────────────────────────────────────────
  # validate_combination/1
  # ──────────────────────────────────────────

  describe "validate_combination/1 - satu kombinasi ditolak" do
    test ":many_to_many + :exact_preference ditolak (Decision Log #44)" do
      assert {:error, msg} =
               Router.validate_combination(
                 profile(%{cardinality: :many_to_many, resolution_mode: :exact_preference})
               )

      assert msg =~ "many_to_many"
      assert msg =~ "exact_preference"
    end

    test ":one_to_one + :divisible diizinkan (Decision Log #45)" do
      assert :ok =
               Router.validate_combination(
                 profile(%{cardinality: :one_to_one, divisibility: :divisible})
               )
    end

    test "kombinasi lain diizinkan" do
      assert :ok = Router.validate_combination(profile(%{cardinality: :one_to_one}))
      assert :ok = Router.validate_combination(profile(%{cardinality: :many_to_one}))
      assert :ok = Router.validate_combination(profile(%{cardinality: :many_to_many, resolution_mode: :fuzzy_score}))
      assert :ok = Router.validate_combination(profile(%{cardinality: :many_to_many, resolution_mode: :negotiated}))
    end
  end

  # ──────────────────────────────────────────
  # pipeline_modifiers/1
  # ──────────────────────────────────────────

  describe "pipeline_modifiers/1 - 6 dimensi non-topologi" do
    test "spatiality :remote -> skip_geo_filter? true" do
      assert %{skip_geo_filter?: true} = Router.pipeline_modifiers(profile(%{spatiality: :remote}))
    end

    test "spatiality :location_bound -> skip_geo_filter? false" do
      assert %{skip_geo_filter?: false} = Router.pipeline_modifiers(profile(%{spatiality: :location_bound}))
    end

    test "trust_level :verified_required -> requires_verification_gate? true" do
      assert %{requires_verification_gate?: true} =
               Router.pipeline_modifiers(profile(%{trust_level: :verified_required}))
    end

    test "trust_level :open -> requires_verification_gate? false" do
      assert %{requires_verification_gate?: false} =
               Router.pipeline_modifiers(profile(%{trust_level: :open}))
    end

    test "visibility :anonymous_until_match -> mask_identity_until_match? true" do
      assert %{mask_identity_until_match?: true} =
               Router.pipeline_modifiers(profile(%{visibility: :anonymous_until_match}))
    end

    test "visibility selain :anonymous_until_match -> mask_identity_until_match? false" do
      assert %{mask_identity_until_match?: false} = Router.pipeline_modifiers(profile(%{visibility: :public}))
      assert %{mask_identity_until_match?: false} = Router.pipeline_modifiers(profile(%{visibility: :private}))
    end

    test "urgency :emergency -> notification_sla :immediate" do
      assert %{notification_sla: :immediate} = Router.pipeline_modifiers(profile(%{urgency: :emergency}))
    end

    test "urgency :urgent -> notification_sla :fast" do
      assert %{notification_sla: :fast} = Router.pipeline_modifiers(profile(%{urgency: :urgent}))
    end

    test "urgency :normal -> notification_sla :batched" do
      assert %{notification_sla: :batched} = Router.pipeline_modifiers(profile(%{urgency: :normal}))
    end
  end
end
