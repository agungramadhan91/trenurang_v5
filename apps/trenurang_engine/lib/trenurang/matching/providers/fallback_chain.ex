defmodule Trenurang.Matching.Providers.FallbackChain do
  @moduledoc """
  Mencoba tiap provider embedding secara berurutan sampai salah satu berhasil.
  Urutan default: Gemini -> OpenRouter -> (Bumblebee, backlog B14, belum diimplementasi).

  Kalau SEMUA provider gagal, kembalikan {:error, :all_providers_failed} --
  ini BUKAN error yang menghentikan pipeline. Caller (Scoring, fase berikutnya)
  yang bertanggung jawab menerjemahkan ini jadi semantic_similarity netral 0.5
  (Decision Log #34).
  """

  alias Trenurang.Matching.Providers.{Gemini, OpenRouter}

  @default_chain [Gemini, OpenRouter]

  @doc """
  opts:
    - :chain - override daftar provider (dipakai testing, default: @default_chain)
    - :provider_opts - diteruskan apa adanya ke setiap provider.embed/2
  """
  @spec embed(String.t(), keyword()) :: {:ok, [float()]} | {:error, :all_providers_failed}
  def embed(text, opts \\ []) do
    chain = Keyword.get(opts, :chain, @default_chain)
    provider_opts = Keyword.get(opts, :provider_opts, [])

    try_providers(text, chain, provider_opts)
  end

  defp try_providers(_text, [], _provider_opts), do: {:error, :all_providers_failed}

  defp try_providers(text, [provider | rest], provider_opts) do
    case provider.embed(text, provider_opts) do
      {:ok, vector} -> {:ok, vector}
      {:error, _reason} -> try_providers(text, rest, provider_opts)
    end
  end
end
