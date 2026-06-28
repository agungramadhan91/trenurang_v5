defmodule Trenurang.Accounts.UserTest do
  use Trenurang.DataCase, async: true

  alias Trenurang.Accounts.User

  describe "changeset/2" do
    test "valid tanpa active_actor_id (default state User baru)" do
      changeset = User.changeset(%User{}, %{})
      assert changeset.valid?
    end

    test "valid dengan active_actor_id" do
      changeset = User.changeset(%User{}, %{active_actor_id: Ecto.UUID.generate()})
      assert changeset.valid?
      assert get_change(changeset, :active_actor_id)
    end
  end

  describe "ghost?/1" do
    test "true kalau active_actor_id nil" do
      assert User.ghost?(%User{active_actor_id: nil})
    end

    test "false kalau active_actor_id terisi" do
      refute User.ghost?(%User{active_actor_id: Ecto.UUID.generate()})
    end
  end

  describe "insert ke DB" do
    test "User baru otomatis ghost (active_actor_id nil)" do
      user = Trenurang.Fixtures.user_fixture()
      assert user.id
      assert User.ghost?(user)
    end
  end
end
