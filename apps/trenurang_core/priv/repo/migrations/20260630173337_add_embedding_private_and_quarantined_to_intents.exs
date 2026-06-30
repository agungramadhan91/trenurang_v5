defmodule Trenurang.Repo.Migrations.AddEmbeddingPrivateAndQuarantinedToIntents do
  use Ecto.Migration

  def change do
    alter table(:intents) do
      add :embedding_private, :boolean, default: false, null: false
    end
  end
end
