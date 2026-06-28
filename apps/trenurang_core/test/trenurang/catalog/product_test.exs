defmodule Trenurang.Catalog.ProductTest do
  use Trenurang.DataCase, async: true

  alias Trenurang.Catalog.Product
  alias Trenurang.Fixtures
  alias Trenurang.Repo

  defp valid_attrs(actor, category, overrides) do
    Map.merge(%{actor_id: actor.id, category_id: category.id, name: "Kursi Kayu"}, overrides)
  end

  describe "changeset/2" do
    test "valid dengan actor_id, category_id, name lengkap" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      changeset = Product.changeset(%Product{}, valid_attrs(actor, category, %{}))
      assert changeset.valid?
    end

    test "invalid kalau actor_id, category_id, name kosong" do
      changeset = Product.changeset(%Product{}, %{})
      refute changeset.valid?

      assert %{
               actor_id: ["can't be blank"],
               category_id: ["can't be blank"],
               name: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "unit_price bisa cast dari string decimal" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      changeset = Product.changeset(%Product{}, valid_attrs(actor, category, %{unit_price: "19.99"}))
      assert changeset.valid?
      assert Decimal.equal?(get_change(changeset, :unit_price), Decimal.new("19.99"))
    end
  end

  describe "foreign_key_constraint" do
    test "actor_id yang gak exist -> error changeset" do
      category = Fixtures.category_fixture()
      changeset = Product.changeset(%Product{}, valid_attrs(%{id: Ecto.UUID.generate()}, category, %{}))

      assert {:error, changeset} = Repo.insert(changeset)
      assert %{actor_id: ["actor tidak ditemukan"]} = errors_on(changeset)
    end

    test "category_id yang gak exist -> error changeset" do
      actor = Fixtures.actor_fixture()
      changeset = Product.changeset(%Product{}, valid_attrs(actor, %{id: Ecto.UUID.generate()}, %{}))

      assert {:error, changeset} = Repo.insert(changeset)
      assert %{category_id: ["category tidak ditemukan"]} = errors_on(changeset)
    end
  end
end
