defmodule Trenurang.Catalog.CategoryTest do
  use Trenurang.DataCase, async: true

  alias Trenurang.Catalog.Category
  alias Trenurang.Repo

  describe "changeset/2" do
    test "valid dengan cuma name" do
      changeset = Category.changeset(%Category{}, %{name: "Elektronik"})
      assert changeset.valid?
    end

    test "invalid kalau name kosong" do
      changeset = Category.changeset(%Category{}, %{})
      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    test "valid dengan semua field opsional terisi" do
      attrs = %{
        name: "Layanan Kesehatan",
        is_active: true,
        dimension_profile_overrides: %{"urgency" => "immediate"},
        scoring_weight_overrides: %{"geo_proximity" => 0.5},
        permitted_filter_dimensions: ["gender", "age_range"],
        regulatory_domain: :health_product,
        required_actor_fields_for_category: ["license_number"]
      }

      changeset = Category.changeset(%Category{}, attrs)
      assert changeset.valid?
    end

    test "invalid kalau regulatory_domain bukan salah satu dari 4 yang diizinkan" do
      changeset = Category.changeset(%Category{}, %{name: "Test", regulatory_domain: "narkoba"})
      refute changeset.valid?
      assert %{regulatory_domain: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "default values" do
    test "is_active default false, override fields default kosong" do
      category = %Category{} |> Category.changeset(%{name: "Olahraga"}) |> Repo.insert!()

      assert category.is_active == false
      assert category.dimension_profile_overrides == %{}
      assert category.scoring_weight_overrides == %{}
      assert category.permitted_filter_dimensions == []
      assert category.required_actor_fields_for_category == []
      assert category.regulatory_domain == nil
    end
  end

  describe "hierarki parent/children" do
    test "child category nyimpen parent_id, dan parent bisa preload children" do
      parent = %Category{} |> Category.changeset(%{name: "Makanan"}) |> Repo.insert!()
      child = %Category{} |> Category.changeset(%{name: "Makanan Beku", parent_id: parent.id}) |> Repo.insert!()

      assert child.parent_id == parent.id

      parent = Repo.preload(parent, :children)
      assert [%Category{id: child_id}] = parent.children
      assert child_id == child.id
    end

    test "parent_id yang gak exist -> error changeset yang rapi, bukan crash" do
      changeset = Category.changeset(%Category{}, %{name: "Anak Tanpa Induk", parent_id: Ecto.UUID.generate()})

      assert {:error, changeset} = Repo.insert(changeset)
      assert %{parent_id: ["kategori induk tidak ditemukan"]} = errors_on(changeset)
    end
  end
end
