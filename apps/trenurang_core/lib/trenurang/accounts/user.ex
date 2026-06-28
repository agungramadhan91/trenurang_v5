defmodule Trenurang.Accounts.User do
  @moduledoc """
  Identitas -- TERPISAH dari peran ekonomi (Actor). Satu User bisa punya
  banyak Actor (1:N). `active_actor_id` cache konteks yang sedang dipakai.

  `ghost?/1` -- User tanpa Actor sama sekali = ghost/guest user. Boleh
  browse/search, belum boleh aksi yang butuh Actor.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "users" do
    field :active_actor_id, :binary_id

    has_many :actors, Trenurang.Accounts.Actor
    has_many :channel_identities, Trenurang.Accounts.ChannelIdentity

    timestamps()
  end

  @type t :: %__MODULE__{}
  @spec ghost?(t()) :: boolean()

  def ghost?(%__MODULE__{active_actor_id: nil}), do: true
  def ghost?(%__MODULE__{}), do: false

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:active_actor_id])
  end
end
