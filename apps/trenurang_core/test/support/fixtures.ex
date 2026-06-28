defmodule Trenurang.Fixtures do
  @moduledoc """
  Helper bikin data dasar buat test (User, Actor, dst).
  Ditambah incremental tiap kali kita masuk ke schema baru.
  """

  alias Trenurang.Accounts.{Actor, User}
  alias Trenurang.Catalog.Category
  alias Trenurang.Repo

  def user_fixture(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert!()
  end

  def actor_fixture(attrs \\ %{}) do
    {user, attrs} = Map.pop(attrs, :user)
    user = user || user_fixture()

    attrs =
      %{type: :human, display_name: "Test Actor"}
      |> Map.merge(attrs)
      |> Map.put(:user_id, user.id)

    %Actor{}
    |> Actor.changeset(attrs)
    |> Repo.insert!()
  end

  def category_fixture(attrs \\ %{}) do
    attrs = Map.merge(%{name: "Test Category"}, attrs)

    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert!()
  end
end
