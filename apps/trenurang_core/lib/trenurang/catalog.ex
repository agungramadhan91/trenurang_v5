defmodule Trenurang.Catalog do
  @moduledoc "Context Catalog -- create untuk Category, Profile, Product, Program."

  alias Trenurang.Catalog.{Category, Product, Profile, Program}
  alias Trenurang.Repo

  @spec create_category(map()) :: {:ok, Category.t()} | {:error, Ecto.Changeset.t()}
  def create_category(attrs) do
    %Category{} |> Category.changeset(attrs) |> Repo.insert()
  end

  @spec create_profile(map()) :: {:ok, Profile.t()} | {:error, Ecto.Changeset.t()}
  def create_profile(attrs) do
    %Profile{} |> Profile.changeset(attrs) |> Repo.insert()
  end

  @spec create_product(map()) :: {:ok, Product.t()} | {:error, Ecto.Changeset.t()}
  def create_product(attrs) do
    %Product{} |> Product.changeset(attrs) |> Repo.insert()
  end

  @spec create_program(map()) :: {:ok, Program.t()} | {:error, Ecto.Changeset.t()}
  def create_program(attrs) do
    %Program{} |> Program.changeset(attrs) |> Repo.insert()
  end
end
