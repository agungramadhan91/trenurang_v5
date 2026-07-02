defmodule Trenurang.Matching.Providers.EmbeddingProvider do
  @moduledoc """
  Behaviour kontrak untuk semua provider embedding (Gemini, OpenRouter, Bumblebee nanti).
  FallbackChain memanggil embed/2 secara berurutan sampai salah satu berhasil.
  """

  @doc """
  Menghasilkan vector embedding dari teks.
  opts dipakai untuk override konfigurasi HTTP request (dipakai saat testing).
  """
  @callback embed(text :: String.t(), opts :: keyword()) ::
              {:ok, [float()]} | {:error, term()}
end
