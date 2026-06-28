defmodule Trenurang.Fixtures do
  @moduledoc """
  Helper bikin data dasar buat test (User, Actor, dst).
  Ditambah incremental tiap kali kita masuk ke schema baru.
  """

  alias Trenurang.Accounts.User
  alias Trenurang.Repo

  def user_fixture(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert!()
  end
end
