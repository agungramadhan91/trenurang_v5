defmodule Trenurang.Repo.Migrations.RenameCatalogTablesToEnglish do
  use Ecto.Migration

  def change do
    rename table(:personas), to: table(:profiles)
    rename table(:produks), to: table(:products)
    rename table(:agenda_programs), to: table(:programs)
  end
end
