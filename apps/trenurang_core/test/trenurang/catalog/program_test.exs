defmodule Trenurang.Catalog.ProgramTest do
  use Trenurang.DataCase, async: true

  alias Trenurang.Catalog.Program
  alias Trenurang.Fixtures
  alias Trenurang.Repo

  defp valid_attrs(actor, category, overrides) do
    Map.merge(%{actor_id: actor.id, category_id: category.id, title: "Pelatihan Las Dasar"}, overrides)
  end

  describe "changeset/2" do
    test "valid dengan actor_id, category_id, title lengkap" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      changeset = Program.changeset(%Program{}, valid_attrs(actor, category, %{}))
      assert changeset.valid?
    end

    test "invalid kalau actor_id, category_id, title kosong" do
      changeset = Program.changeset(%Program{}, %{})
      refute changeset.valid?

      assert %{
               actor_id: ["can't be blank"],
               category_id: ["can't be blank"],
               title: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "starts_at/ends_at/capacity bisa diisi" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      changeset =
        Program.changeset(
          %Program{},
          valid_attrs(actor, category, %{
            starts_at: ~U[2026-08-01 09:00:00Z],
            ends_at: ~U[2026-08-01 17:00:00Z],
            capacity: 30
          })
        )

      assert changeset.valid?
      assert get_change(changeset, :capacity) == 30
    end
  end

  describe "foreign_key_constraint" do
    test "actor_id yang gak exist -> error changeset" do
      category = Fixtures.category_fixture()
      changeset = Program.changeset(%Program{}, valid_attrs(%{id: Ecto.UUID.generate()}, category, %{}))

      assert {:error, changeset} = Repo.insert(changeset)
      assert %{actor_id: ["actor tidak ditemukan"]} = errors_on(changeset)
    end

    test "category_id yang gak exist -> error changeset" do
      actor = Fixtures.actor_fixture()
      changeset = Program.changeset(%Program{}, valid_attrs(actor, %{id: Ecto.UUID.generate()}, %{}))

      assert {:error, changeset} = Repo.insert(changeset)
      assert %{category_id: ["category tidak ditemukan"]} = errors_on(changeset)
    end
  end
end
