defmodule Trenurang.Accounts.ChannelIdentity do
  @moduledoc """
  Penghubung User <-> identitas di channel tertentu (Telegram chat_id, dst).
  Satu kombinasi {channel, channel_user_id} cuma boleh terhubung ke satu User.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "channel_identities" do
    field :channel, Ecto.Enum, values: [:telegram, :web, :rest_api]
    field :channel_user_id, :string

    belongs_to :user, Trenurang.Accounts.User

    timestamps()
  end

  @type t :: %__MODULE__{}

  def changeset(channel_identity, attrs) do
    channel_identity
    |> cast(attrs, [:channel, :channel_user_id, :user_id])
    |> validate_required([:channel, :channel_user_id, :user_id])
    |> unique_constraint([:channel, :channel_user_id])
  end
end
