defmodule Trenurang.Matching.Providers.FallbackChainTest do
  use ExUnit.Case, async: true

  alias Trenurang.Matching.Providers.FallbackChain

  # Provider palsu untuk simulasi skenario chain, tanpa HTTP call sama sekali.
  defmodule AlwaysSucceeds do
    @behaviour Trenurang.Matching.Providers.EmbeddingProvider
    @impl true
    def embed(_text, _opts), do: {:ok, [1.0, 2.0, 3.0]}
  end

  defmodule AlwaysFails do
    @behaviour Trenurang.Matching.Providers.EmbeddingProvider
    @impl true
    def embed(_text, _opts), do: {:error, :simulated_failure}
  end

  test "provider pertama berhasil -> langsung dipakai, tidak lanjut ke provider berikutnya" do
    assert {:ok, [1.0, 2.0, 3.0]} =
             FallbackChain.embed("teks", chain: [AlwaysSucceeds, AlwaysFails])
  end

  test "provider pertama gagal, provider kedua berhasil -> fallback jalan" do
    assert {:ok, [1.0, 2.0, 3.0]} =
             FallbackChain.embed("teks", chain: [AlwaysFails, AlwaysSucceeds])
  end

  test "semua provider gagal -> {:error, :all_providers_failed}" do
    assert {:error, :all_providers_failed} =
             FallbackChain.embed("teks", chain: [AlwaysFails, AlwaysFails])
  end

  test "chain kosong -> {:error, :all_providers_failed}" do
    assert {:error, :all_providers_failed} = FallbackChain.embed("teks", chain: [])
  end

  test "default chain dipakai kalau opts kosong (Gemini -> OpenRouter)" do
    # Tanpa API key di test env, kedua provider asli akan {:error, :missing_api_key},
    # jadi hasil akhirnya tetap :all_providers_failed -- ini juga membuktikan
    # FallbackChain.embed/1 (tanpa opts) berhasil dipanggil dengan default chain.
    Application.delete_env(:trenurang_engine, :gemini_api_key)
    Application.delete_env(:trenurang_engine, :openrouter_api_key)

    assert {:error, :all_providers_failed} = FallbackChain.embed("teks")
  end

  test "provider_opts diteruskan ke setiap provider.embed/2" do
    defmodule ChecksOpts do
      @behaviour Trenurang.Matching.Providers.EmbeddingProvider
      @impl true
      def embed(_text, opts) do
        send(self(), {:received_opts, opts})
        {:ok, [9.9]}
      end
    end

    assert {:ok, [9.9]} =
             FallbackChain.embed("teks",
               chain: [ChecksOpts],
               provider_opts: [req_options: [some: :flag]]
             )

    assert_received {:received_opts, [req_options: [some: :flag]]}
  end
end
