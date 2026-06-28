defmodule Trenurang.Catalog.Program do
  @moduledoc "Objek katalog cakupan luas: event, lowongan kerja, program pendanaan, dll."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "programs" do
    field :title, :string
    field :description, :string
    field :starts_at, :utc_datetime
    field :ends_at, :utc_datetime
    field :capacity, :integer

    belongs_to :actor, Trenurang.Accounts.Actor
    belongs_to :category, Trenurang.Catalog.Category

    timestamps()
  end

  @type t :: %__MODULE__{}

  def changeset(program, attrs) do
    program
    |> cast(attrs, [:actor_id, :category_id, :title, :description, :starts_at, :ends_at, :capacity])
    |> validate_required([:actor_id, :category_id, :title])
    |> foreign_key_constraint(:actor_id, message: "actor tidak ditemukan")
    |> foreign_key_constraint(:category_id, message: "category tidak ditemukan")
  end
end
