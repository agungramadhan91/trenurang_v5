defmodule Trenurang.AccountsTest do
  use Trenurang.DataCase, async: true

  alias Trenurang.Accounts
  alias Trenurang.Accounts.{Actor, User}
  alias Trenurang.Fixtures
  alias Trenurang.Repo

  describe "register_actor/2" do
    test "Actor pertama otomatis jadi active_actor_id User" do
      user = Fixtures.user_fixture()

      assert {:ok, actor} = Accounts.register_actor(user, %{type: :human, display_name: "Budi"})

      updated_user = Repo.get!(User, user.id)
      assert updated_user.active_actor_id == actor.id
    end

    test "Actor kedua TIDAK mengubah active_actor_id yang udah ke-set" do
      user = Fixtures.user_fixture()

      {:ok, first_actor} = Accounts.register_actor(user, %{type: :human, display_name: "Budi"})

      {:ok, _second_actor} =
        Accounts.register_actor(user, %{type: :bisnis, legal_form: :pt, display_name: "Toko Budi"})

      updated_user = Repo.get!(User, user.id)
      assert updated_user.active_actor_id == first_actor.id
    end

    test "user_id otomatis di-set dari argumen user, attrs gak perlu nyertain" do
      user = Fixtures.user_fixture()

      {:ok, actor} = Accounts.register_actor(user, %{type: :human, display_name: "Budi"})
      assert actor.user_id == user.id
    end

    test "attrs invalid -> {:error, changeset}, gak ada Actor ke-insert (rollback)" do
      user = Fixtures.user_fixture()
      count_before = Repo.aggregate(Actor, :count)

      assert {:error, changeset} = Accounts.register_actor(user, %{type: :human})

      refute changeset.valid?
      assert %{display_name: ["can't be blank"]} = errors_on(changeset)
      assert Repo.aggregate(Actor, :count) == count_before
    end
  end
end
