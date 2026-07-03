defmodule Trenurang.Catalog.TaxonomyTest do
  use Trenurang.DataCase, async: true

  alias Trenurang.Catalog.Taxonomy
  alias Trenurang.Fixtures

  describe "resolve_effective_profile/2" do
    test "category root tanpa parent -- balikin overrides sendiri" do
      category = Fixtures.category_fixture(%{dimension_profile_overrides: %{"urgency" => "immediate"}})

      assert Taxonomy.resolve_effective_profile(category) == %{"urgency" => "immediate"}
    end

    test "child mewarisi key yang DIOMIT dari parent, override key yang disebut" do
      parent =
        Fixtures.category_fixture(%{
          dimension_profile_overrides: %{"urgency" => "scheduled", "cardinality" => "one_to_one"}
        })

      child =
        Fixtures.category_fixture(%{
          parent_id: parent.id,
          dimension_profile_overrides: %{"urgency" => "immediate"}
        })

      assert Taxonomy.resolve_effective_profile(child) == %{
               "urgency" => "immediate",
               "cardinality" => "one_to_one"
             }
    end

    test "cascading jalan sampai 3 level (root -> middle -> leaf)" do
      root = Fixtures.category_fixture(%{dimension_profile_overrides: %{"trust_level" => "verified_only"}})

      middle =
        Fixtures.category_fixture(%{
          parent_id: root.id,
          dimension_profile_overrides: %{"cardinality" => "one_to_many"}
        })

      leaf =
        Fixtures.category_fixture(%{
          parent_id: middle.id,
          dimension_profile_overrides: %{"urgency" => "immediate"}
        })

      assert Taxonomy.resolve_effective_profile(leaf) == %{
               "trust_level" => "verified_only",
               "cardinality" => "one_to_many",
               "urgency" => "immediate"
             }
    end

    test "explicit_overrides (arg ke-2) menang di atas semua level Category" do
      category = Fixtures.category_fixture(%{dimension_profile_overrides: %{"urgency" => "scheduled"}})

      assert Taxonomy.resolve_effective_profile(category, %{"urgency" => "immediate"}) == %{
               "urgency" => "immediate"
             }
    end

    test "GOTCHA terdokumentasi: child set key ke nil EKSPLISIT (bukan diomit) -- nil BOCOR, gak fallback ke parent" do
      parent = Fixtures.category_fixture(%{dimension_profile_overrides: %{"urgency" => "scheduled"}})

      # Salah: nyimpen key dengan value nil BUKAN cara "warisin dari parent".
      # Cara yang benar buat warisin = jangan sebut key-nya sama sekali
      # (lihat test "child mewarisi key yang DIOMIT" di atas).
      child =
        Fixtures.category_fixture(%{
          parent_id: parent.id,
          dimension_profile_overrides: %{"urgency" => nil}
        })

      assert Taxonomy.resolve_effective_profile(child) == %{"urgency" => nil}
    end
  end

  describe "resolve_effective_weights/1" do
    test "cascading 2 level -- child override key yang disebut, warisin key yang diomit" do
      parent =
        Fixtures.category_fixture(%{
          scoring_weight_overrides: %{"geo_proximity" => 0.5, "recency" => 0.2}
        })

      child =
        Fixtures.category_fixture(%{
          parent_id: parent.id,
          scoring_weight_overrides: %{"geo_proximity" => 0.8}
        })

      assert Taxonomy.resolve_effective_weights(child) == %{
               "geo_proximity" => 0.8,
               "recency" => 0.2
             }
    end
  end

  describe "resolve_effective_half_life/1" do
    test "category isi sendiri -- balikin nilai sendiri" do
      category =
        Fixtures.category_fixture(%{geo_half_life_km: 3.0, recency_half_life_days: 2.0})

      assert Taxonomy.resolve_effective_half_life(category) == %{
               geo_half_life_km: 3.0,
               recency_half_life_days: 2.0
             }
    end

    test "child nil -- warisin dari parent" do
      parent =
        Fixtures.category_fixture(%{geo_half_life_km: 15.0, recency_half_life_days: 30.0})

      child = Fixtures.category_fixture(%{parent_id: parent.id})

      assert Taxonomy.resolve_effective_half_life(child) == %{
               geo_half_life_km: 15.0,
               recency_half_life_days: 30.0
             }
    end

    test "child override sebagian -- geo dari child, recency warisin parent" do
      parent =
        Fixtures.category_fixture(%{geo_half_life_km: 15.0, recency_half_life_days: 30.0})

      child = Fixtures.category_fixture(%{parent_id: parent.id, geo_half_life_km: 1.5})

      assert Taxonomy.resolve_effective_half_life(child) == %{
               geo_half_life_km: 1.5,
               recency_half_life_days: 30.0
             }
    end

    test "seluruh chain nil -- fallback ke default platform" do
      root = Fixtures.category_fixture(%{})
      leaf = Fixtures.category_fixture(%{parent_id: root.id})

      assert Taxonomy.resolve_effective_half_life(leaf) == %{
               geo_half_life_km: 10.0,
               recency_half_life_days: 7.0
             }
    end
  end
end
