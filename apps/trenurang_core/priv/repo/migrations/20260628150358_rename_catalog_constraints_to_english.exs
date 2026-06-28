defmodule Trenurang.Repo.Migrations.RenameCatalogConstraintsToEnglish do
  use Ecto.Migration

  def change do
    # profiles (sebelumnya personas)
    execute(
      "ALTER TABLE profiles RENAME CONSTRAINT personas_pkey TO profiles_pkey",
      "ALTER TABLE profiles RENAME CONSTRAINT profiles_pkey TO personas_pkey"
    )

    execute(
      "ALTER TABLE profiles RENAME CONSTRAINT personas_actor_id_fkey TO profiles_actor_id_fkey",
      "ALTER TABLE profiles RENAME CONSTRAINT profiles_actor_id_fkey TO personas_actor_id_fkey"
    )

    execute(
      "ALTER INDEX personas_actor_id_index RENAME TO profiles_actor_id_index",
      "ALTER INDEX profiles_actor_id_index RENAME TO personas_actor_id_index"
    )

    # products (sebelumnya produks)
    execute(
      "ALTER TABLE products RENAME CONSTRAINT produks_pkey TO products_pkey",
      "ALTER TABLE products RENAME CONSTRAINT products_pkey TO produks_pkey"
    )

    execute(
      "ALTER TABLE products RENAME CONSTRAINT produks_actor_id_fkey TO products_actor_id_fkey",
      "ALTER TABLE products RENAME CONSTRAINT products_actor_id_fkey TO produks_actor_id_fkey"
    )

    execute(
      "ALTER TABLE products RENAME CONSTRAINT produks_category_id_fkey TO products_category_id_fkey",
      "ALTER TABLE products RENAME CONSTRAINT products_category_id_fkey TO produks_category_id_fkey"
    )

    execute(
      "ALTER INDEX produks_actor_id_index RENAME TO products_actor_id_index",
      "ALTER INDEX products_actor_id_index RENAME TO produks_actor_id_index"
    )

    execute(
      "ALTER INDEX produks_category_id_index RENAME TO products_category_id_index",
      "ALTER INDEX products_category_id_index RENAME TO produks_category_id_index"
    )

    # programs (sebelumnya agenda_programs)
    execute(
      "ALTER TABLE programs RENAME CONSTRAINT agenda_programs_pkey TO programs_pkey",
      "ALTER TABLE programs RENAME CONSTRAINT programs_pkey TO agenda_programs_pkey"
    )

    execute(
      "ALTER TABLE programs RENAME CONSTRAINT agenda_programs_actor_id_fkey TO programs_actor_id_fkey",
      "ALTER TABLE programs RENAME CONSTRAINT programs_actor_id_fkey TO agenda_programs_actor_id_fkey"
    )

    execute(
      "ALTER TABLE programs RENAME CONSTRAINT agenda_programs_category_id_fkey TO programs_category_id_fkey",
      "ALTER TABLE programs RENAME CONSTRAINT programs_category_id_fkey TO agenda_programs_category_id_fkey"
    )

    execute(
      "ALTER INDEX agenda_programs_actor_id_index RENAME TO programs_actor_id_index",
      "ALTER INDEX programs_actor_id_index RENAME TO agenda_programs_actor_id_index"
    )

    execute(
      "ALTER INDEX agenda_programs_category_id_index RENAME TO programs_category_id_index",
      "ALTER INDEX programs_category_id_index RENAME TO agenda_programs_category_id_index"
    )
  end
end
