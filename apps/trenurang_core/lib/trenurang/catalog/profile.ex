defmodule Trenurang.Catalog.Profile do
  @moduledoc """
  Objek katalog untuk Actor :human (atau Bisnis perorangan informal) --
  TERPISAH dari Intent. `direction` (supply/demand) ada di Intent,
  BUKAN di sini.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "profiles" do
    field :display_name, :string
    field :skills, {:array, :string}, default: []
    field :description, :string

    belongs_to :actor, Trenurang.Accounts.Actor

    timestamps()
  end

  @type t :: %__MODULE__{}

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:actor_id, :display_name, :skills, :description])
    |> validate_required([:actor_id])
    |> foreign_key_constraint(:actor_id, message: "actor tidak ditemukan")
  end
end
