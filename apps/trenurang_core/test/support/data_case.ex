defmodule Trenurang.DataCase do
  @moduledoc """
  ExUnit.CaseTemplate untuk test yang butuh Trenurang.Repo.
  Setup otomatis checkout sandbox per test (isolated, auto-rollback
  di akhir test, gak ninggalin data sampah di DB).
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Trenurang.Repo

      import Ecto
      import Ecto.Query
      import Ecto.Changeset
      import Trenurang.DataCase
    end
  end

  setup tags do
    Trenurang.DataCase.setup_sandbox(tags)
    :ok
  end

  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Trenurang.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc "Ubah error changeset jadi map biasa, biar gampang di-assert di test."
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
