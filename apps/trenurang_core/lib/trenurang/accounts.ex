defmodule Trenurang.Accounts do
  @moduledoc """
  Context Accounts. `register_actor/2` satu-satunya entry point bikin
  Actor baru. Kalau ini Actor PERTAMA milik User, langsung jadi
  active_actor_id.
  """

  alias Trenurang.Accounts.{Actor, User}
  alias Trenurang.Repo

  @spec register_actor(User.t(), map()) :: {:ok, Actor.t()} | {:error, Ecto.Changeset.t()}
  def register_actor(%User{} = user, attrs) do
    attrs =
      attrs
      |> stringify_keys()
      |> Map.put("user_id", user.id)

    Repo.transaction(fn ->
      case %Actor{} |> Actor.changeset(attrs) |> Repo.insert() do
        {:ok, actor} ->
          user |> Repo.reload!() |> maybe_set_active_actor(actor)
          actor

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp maybe_set_active_actor(%User{active_actor_id: nil} = user, %Actor{} = actor) do
    user |> User.changeset(%{active_actor_id: actor.id}) |> Repo.update!()
  end

  defp maybe_set_active_actor(_user, _actor), do: :ok

  defp stringify_keys(attrs) do
    for {k, v} <- attrs, into: %{}, do: {to_string(k), v}
  end
end
