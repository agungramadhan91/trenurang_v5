defmodule Trenurang.Catalog.Product do
  @moduledoc "Objek katalog untuk Actor :bisnis/:organisasi (barang/jasa terstruktur)."
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "products" do
    field :name, :string
    field :description, :string
    field :unit_price, :decimal
    field :stock_quantity, :integer

    belongs_to :actor, Trenurang.Accounts.Actor
    belongs_to :category, Trenurang.Catalog.Category

    timestamps()
  end

  @type t :: %__MODULE__{}

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:actor_id, :category_id, :name, :description, :unit_price, :stock_quantity])
    |> validate_required([:actor_id, :category_id, :name])
  end
end
