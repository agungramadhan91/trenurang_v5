defmodule Trenurang.Accounts.ChannelIdentityTest do
  use Trenurang.DataCase, async: true

  alias Trenurang.Accounts.ChannelIdentity
  alias Trenurang.Fixtures

  describe "changeset/2" do
    test "valid dengan channel, channel_user_id, user_id lengkap" do
      user = Fixtures.user_fixture()

      changeset =
        ChannelIdentity.changeset(%ChannelIdentity{}, %{
          channel: :telegram,
          channel_user_id: "123456789",
          user_id: user.id
        })

      assert changeset.valid?
    end

    test "invalid kalau channel, channel_user_id, user_id kosong" do
      changeset = ChannelIdentity.changeset(%ChannelIdentity{}, %{})

      refute changeset.valid?

      assert %{
               channel: ["can't be blank"],
               channel_user_id: ["can't be blank"],
               user_id: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "invalid kalau channel bukan :telegram/:web/:rest_api" do
      changeset = ChannelIdentity.changeset(%ChannelIdentity{}, %{channel: "sms"})

      refute changeset.valid?
      assert %{channel: ["is invalid"]} = errors_on(changeset)
    end
  end

  describe "unique_constraint" do
    test "kombinasi {channel, channel_user_id} gak boleh duplikat" do
      user = Fixtures.user_fixture()
      attrs = %{channel: :telegram, channel_user_id: "999", user_id: user.id}

      assert {:ok, _} = %ChannelIdentity{} |> ChannelIdentity.changeset(attrs) |> Repo.insert()

      assert {:error, changeset} =
               %ChannelIdentity{} |> ChannelIdentity.changeset(attrs) |> Repo.insert()

      assert %{channel: ["has already been taken"]} = errors_on(changeset)
    end

    test "channel_user_id sama tapi channel beda -- boleh" do
      user = Fixtures.user_fixture()

      assert {:ok, _} =
               %ChannelIdentity{}
               |> ChannelIdentity.changeset(%{channel: :telegram, channel_user_id: "777", user_id: user.id})
               |> Repo.insert()

      assert {:ok, _} =
               %ChannelIdentity{}
               |> ChannelIdentity.changeset(%{channel: :web, channel_user_id: "777", user_id: user.id})
               |> Repo.insert()
    end
  end
end
