defmodule Trenurang.CatalogTest do
  use Trenurang.DataCase, async: true

  alias Trenurang.Catalog
  alias Trenurang.Fixtures

  describe "create_category/1" do
    test "valid attrs -> {:ok, category}" do
      assert {:ok, category} = Catalog.create_category(%{name: "Elektronik"})
      assert category.name == "Elektronik"
    end

    test "invalid attrs -> {:error, changeset}" do
      assert {:error, changeset} = Catalog.create_category(%{})
      refute changeset.valid?
    end
  end

  describe "create_profile/1" do
    test "valid attrs -> {:ok, profile}" do
      actor = Fixtures.actor_fixture()
      assert {:ok, profile} = Catalog.create_profile(%{actor_id: actor.id, display_name: "Budi"})
      assert profile.actor_id == actor.id
    end

    test "invalid attrs -> {:error, changeset}" do
      assert {:error, changeset} = Catalog.create_profile(%{})
      refute changeset.valid?
    end
  end

  describe "create_product/1" do
    test "valid attrs -> {:ok, product}" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      assert {:ok, product} =
               Catalog.create_product(%{actor_id: actor.id, category_id: category.id, name: "Kursi"})

      assert product.name == "Kursi"
    end

    test "invalid attrs -> {:error, changeset}" do
      assert {:error, changeset} = Catalog.create_product(%{})
      refute changeset.valid?
    end
  end

  describe "create_program/1" do
    test "valid attrs -> {:ok, program}" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      assert {:ok, program} =
               Catalog.create_program(%{actor_id: actor.id, category_id: category.id, title: "Pelatihan"})

      assert program.title == "Pelatihan"
    end

    test "invalid attrs -> {:error, changeset}" do
      assert {:error, changeset} = Catalog.create_program(%{})
      refute changeset.valid?
    end
  end
end
