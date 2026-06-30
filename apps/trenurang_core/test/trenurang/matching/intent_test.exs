defmodule Trenurang.Matching.IntentTest do
  use Trenurang.DataCase, async: true

  alias Trenurang.Matching.Intent
  alias Trenurang.Fixtures
  alias Trenurang.Repo

  defp valid_attrs(actor, category, overrides) do
    Map.merge(
      %{
        direction: :supply,
        source_type: "Product",
        source_id: Ecto.UUID.generate(),
        actor_id: actor.id,
        category_id: category.id,
        dimension_profile: %{"urgency" => "immediate"}
      },
      overrides
    )
  end

  describe "changeset/2 - required fields" do
    test "invalid kalau direction/source_type/source_id/actor_id/category_id kosong" do
      changeset = Intent.changeset(%Intent{}, %{})
      refute changeset.valid?

      assert %{
               direction: ["can't be blank"],
               source_type: ["can't be blank"],
               source_id: ["can't be blank"],
               actor_id: ["can't be blank"],
               category_id: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "dimension_profile kosong (%{}) LOLOS validate_required -- known gap, bukan bug" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      # Ecto validate_required cuma anggap "blank" kalau nil/string kosong --
      # map kosong %{} tetap dianggap "ada nilai", jadi field ini gak pernah
      # ke-flag walau attrs gak nyertain dimension_profile sama sekali.
      # Validasi "profile harus lengkap 9 dimensi" SENGAJA bukan tugas
      # Intent.changeset/2 -- itu tugas layer Matching context (Router/Scoring)
      # yang belum kita bangun. Test ini dokumentasikan gap-nya, bukan nambal.
      attrs = valid_attrs(actor, category, %{}) |> Map.delete(:dimension_profile)
      changeset = Intent.changeset(%Intent{}, attrs)

      assert changeset.valid?
      assert get_field(changeset, :dimension_profile) == %{}
    end
  end

  describe "changeset/2 - source_type polymorphic" do
    test "valid untuk Profile/Product/Program" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      for source_type <- ["Profile", "Product", "Program"] do
        changeset = Intent.changeset(%Intent{}, valid_attrs(actor, category, %{source_type: source_type}))
        assert changeset.valid?, "harusnya valid untuk source_type #{source_type}"
      end
    end

    test "invalid kalau source_type bukan Profile/Product/Program" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      changeset = Intent.changeset(%Intent{}, valid_attrs(actor, category, %{source_type: "User"}))

      refute changeset.valid?
      assert %{source_type: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "changeset/2 - direction & status enum" do
    test "direction harus :supply atau :demand" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      changeset = Intent.changeset(%Intent{}, valid_attrs(actor, category, %{direction: "ambigu"}))
      refute changeset.valid?
      assert %{direction: ["is invalid"]} = errors_on(changeset)
    end

    test "status default :active kalau gak diisi" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      intent = %Intent{} |> Intent.changeset(valid_attrs(actor, category, %{})) |> Repo.insert!()
      assert intent.status == :active
    end
  end

  describe "changeset/2 - dimension_profile snapshot" do
    test "dimension_profile disimpan sebagai map bebas (snapshot, bukan referensi)" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      profile = %{"cardinality" => "one_to_one", "urgency" => "immediate"}

      intent =
        %Intent{}
        |> Intent.changeset(valid_attrs(actor, category, %{dimension_profile: profile}))
        |> Repo.insert!()

      assert intent.dimension_profile == profile
    end
  end

  describe "changeset/2 - geo_point & embedding" do
    test "geo_point tersimpan dengan urutan koordinat {lng, lat}, bukan {lat, lng}" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      # Jakarta: lat -6.2, lng 106.816666 -- PostGIS pakai {lng, lat}
      jakarta = %Geo.Point{coordinates: {106.816666, -6.2}, srid: 4326}

      intent =
        %Intent{}
        |> Intent.changeset(valid_attrs(actor, category, %{geo_point: jakarta}))
        |> Repo.insert!()

      assert %Geo.Point{coordinates: {lng, lat}, srid: 4326} = intent.geo_point
      assert_in_delta lng, 106.816666, 0.0001
      assert_in_delta lat, -6.2, 0.0001
    end

    test "embedding tersimpan sebagai array float" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      vector = [0.1, 0.2, 0.3]

      intent =
        %Intent{}
        |> Intent.changeset(valid_attrs(actor, category, %{embedding: vector}))
        |> Repo.insert!()

      assert intent.embedding == vector
    end
  end

  describe "foreign_key_constraint" do
    test "actor_id yang gak exist -> error changeset" do
      category = Fixtures.category_fixture()
      changeset = Intent.changeset(%Intent{}, valid_attrs(%{id: Ecto.UUID.generate()}, category, %{}))

      assert {:error, changeset} = Repo.insert(changeset)
      assert %{actor_id: ["actor tidak ditemukan"]} = errors_on(changeset)
    end

    test "category_id yang gak exist -> error changeset" do
      actor = Fixtures.actor_fixture()
      changeset = Intent.changeset(%Intent{}, valid_attrs(actor, %{id: Ecto.UUID.generate()}, %{}))

      assert {:error, changeset} = Repo.insert(changeset)
      assert %{category_id: ["category tidak ditemukan"]} = errors_on(changeset)
    end
  end

  describe "changeset/2 - embedding_private & status quarantined" do
    test "embedding_private default false kalau tidak diisi" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      intent =
        %Intent{}
        |> Intent.changeset(valid_attrs(actor, category, %{}))
        |> Repo.insert!()

      assert intent.embedding_private == false
    end

    test "embedding_private bisa di-set true" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      intent =
        %Intent{}
        |> Intent.changeset(valid_attrs(actor, category, %{embedding_private: true}))
        |> Repo.insert!()

      assert intent.embedding_private == true
    end

    test "status :quarantined adalah nilai valid" do
      actor = Fixtures.actor_fixture()
      category = Fixtures.category_fixture()

      intent =
        %Intent{}
        |> Intent.changeset(valid_attrs(actor, category, %{status: :quarantined}))
        |> Repo.insert!()

      assert intent.status == :quarantined
    end
  end
end
