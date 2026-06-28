defmodule Trenurang.Accounts.Actor do
  @moduledoc """
  Peran ekonomi, mengikuti klasifikasi UN SNA -- TERPISAH dari identitas
  (User) dan dari objek katalog yang dicocokkan (Persona/Produk/AgendaProgram).

  `legal_form` dan `mandate_type` ORTOGONAL, bukan satu badge gabungan:
  `legal_form` cuma valid kalau type == :bisnis, `mandate_type` cuma valid
  kalau type == :organisasi. Koperasi masuk :bisnis (legal_form: :koperasi),
  bukan :organisasi.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "actors" do
    field :type, Ecto.Enum, values: [:human, :bisnis, :organisasi]
    field :legal_form, Ecto.Enum, values: [:perorangan, :cv, :pt, :koperasi]
    field :mandate_type, Ecto.Enum, values: [:yayasan, :perkumpulan, :lembaga_pemerintah]
    field :display_name, :string

    belongs_to :user, Trenurang.Accounts.User
    has_one :profile, Trenurang.Catalog.Profile
    has_many :products, Trenurang.Catalog.Product
    has_many :programs, Trenurang.Catalog.Program
    has_many :intents, Trenurang.Matching.Intent

    timestamps()
  end

  @type t :: %__MODULE__{}

  def changeset(actor, attrs) do
    actor
    |> cast(attrs, [:user_id, :type, :legal_form, :mandate_type, :display_name])
    |> validate_required([:user_id, :type, :display_name])
    |> validate_legal_form_orthogonality()
  end

  defp validate_legal_form_orthogonality(changeset) do
    type = get_field(changeset, :type)

    changeset
    |> reject_unless(:legal_form, type == :bisnis, "hanya valid untuk Actor type :bisnis")
    |> reject_unless(:mandate_type, type == :organisasi, "hanya valid untuk Actor type :organisasi")
  end

  defp reject_unless(changeset, _field, true, _msg), do: changeset

  defp reject_unless(changeset, field, false, msg) do
    case get_field(changeset, field) do
      nil -> changeset
      _ -> add_error(changeset, field, msg)
    end
  end
end
