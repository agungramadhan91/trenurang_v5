defmodule Trenurang.Accounts.ActorTest do
  use Trenurang.DataCase, async: true

  alias Trenurang.Accounts.Actor
  alias Trenurang.Fixtures

  defp valid_attrs(overrides) do
    Map.merge(
      %{user_id: Ecto.UUID.generate(), type: :human, display_name: "Budi"},
      overrides
    )
  end

  describe "changeset/2 - required fields" do
    test "invalid kalau user_id, type, display_name kosong" do
      changeset = Actor.changeset(%Actor{}, %{})

      refute changeset.valid?

      assert %{
               user_id: ["can't be blank"],
               type: ["can't be blank"],
               display_name: ["can't be blank"]
             } = errors_on(changeset)
    end
  end

  describe "changeset/2 - type enum" do
    test "invalid kalau type bukan :human/:bisnis/:organisasi" do
      changeset = Actor.changeset(%Actor{}, valid_attrs(%{type: "perusahaan"}))

      refute changeset.valid?
      assert %{type: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "changeset/2 - orthogonality legal_form vs type" do
    test ":bisnis boleh isi legal_form (mis. :pt)" do
      changeset = Actor.changeset(%Actor{}, valid_attrs(%{type: :bisnis, legal_form: :pt}))
      assert changeset.valid?
    end

    test ":bisnis dengan legal_form :koperasi tetap valid (koperasi = bisnis, bukan organisasi)" do
      changeset = Actor.changeset(%Actor{}, valid_attrs(%{type: :bisnis, legal_form: :koperasi}))
      assert changeset.valid?
    end

    test ":bisnis dengan legal_form nil tetap valid (opsional)" do
      changeset = Actor.changeset(%Actor{}, valid_attrs(%{type: :bisnis}))
      assert changeset.valid?
    end

    test ":human gak boleh isi legal_form" do
      changeset = Actor.changeset(%Actor{}, valid_attrs(%{type: :human, legal_form: :pt}))

      refute changeset.valid?
      assert %{legal_form: ["hanya valid untuk Actor type :bisnis"]} = errors_on(changeset)
    end

    test ":organisasi gak boleh isi legal_form" do
      changeset = Actor.changeset(%Actor{}, valid_attrs(%{type: :organisasi, legal_form: :cv}))

      refute changeset.valid?
      assert %{legal_form: ["hanya valid untuk Actor type :bisnis"]} = errors_on(changeset)
    end
  end

  describe "changeset/2 - orthogonality mandate_type vs type" do
    test ":organisasi boleh isi mandate_type (mis. :yayasan)" do
      changeset = Actor.changeset(%Actor{}, valid_attrs(%{type: :organisasi, mandate_type: :yayasan}))
      assert changeset.valid?
    end

    test ":bisnis gak boleh isi mandate_type" do
      changeset = Actor.changeset(%Actor{}, valid_attrs(%{type: :bisnis, mandate_type: :yayasan}))

      refute changeset.valid?
      assert %{mandate_type: ["hanya valid untuk Actor type :organisasi"]} = errors_on(changeset)
    end

    test ":human gak boleh isi mandate_type" do
      changeset = Actor.changeset(%Actor{}, valid_attrs(%{type: :human, mandate_type: :perkumpulan}))

      refute changeset.valid?
      assert %{mandate_type: ["hanya valid untuk Actor type :organisasi"]} = errors_on(changeset)
    end
  end

  describe "changeset/2 - kombinasi gagal ganda" do
    test "type :human dengan legal_form DAN mandate_type terisi -> dua error sekaligus" do
      changeset =
        Actor.changeset(
          %Actor{},
          valid_attrs(%{type: :human, legal_form: :pt, mandate_type: :yayasan})
        )

      refute changeset.valid?

      assert %{
               legal_form: ["hanya valid untuk Actor type :bisnis"],
               mandate_type: ["hanya valid untuk Actor type :organisasi"]
             } = errors_on(changeset)
    end
  end

  describe "insert ke DB" do
    test "Actor :bisnis dengan legal_form :koperasi berhasil ke-insert" do
      actor =
        Fixtures.actor_fixture(%{
          type: :bisnis,
          legal_form: :koperasi,
          display_name: "Koperasi Maju"
        })

      assert actor.id
      assert actor.type == :bisnis
      assert actor.legal_form == :koperasi
    end
  end
end
