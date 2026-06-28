defmodule Trenurang.Catalog.ProfileTest do
  use Trenurang.DataCase, async: true

  alias Trenurang.Catalog.Profile
  alias Trenurang.Fixtures
  alias Trenurang.Repo

  describe "changeset/2" do
    test "valid dengan actor_id valid" do
      actor = Fixtures.actor_fixture()
      changeset = Profile.changeset(%Profile{}, %{actor_id: actor.id, display_name: "Budi Tukang Servis"})
      assert changeset.valid?
    end

    test "invalid kalau actor_id kosong" do
      changeset = Profile.changeset(%Profile{}, %{})
      refute changeset.valid?
      assert %{actor_id: ["can't be blank"]} = errors_on(changeset)
    end

    test "skills default kosong kalau gak diisi" do
      actor = Fixtures.actor_fixture()
      profile = %Profile{} |> Profile.changeset(%{actor_id: actor.id}) |> Repo.insert!()
      assert profile.skills == []
    end

    test "skills bisa diisi list string" do
      actor = Fixtures.actor_fixture()
      changeset = Profile.changeset(%Profile{}, %{actor_id: actor.id, skills: ["jahit", "las"]})
      assert changeset.valid?
      assert get_change(changeset, :skills) == ["jahit", "las"]
    end
  end

  describe "foreign_key_constraint" do
    test "actor_id yang gak exist -> error changeset, bukan crash" do
      changeset = Profile.changeset(%Profile{}, %{actor_id: Ecto.UUID.generate()})
      assert {:error, changeset} = Repo.insert(changeset)
      assert %{actor_id: ["actor tidak ditemukan"]} = errors_on(changeset)
    end
  end
end
