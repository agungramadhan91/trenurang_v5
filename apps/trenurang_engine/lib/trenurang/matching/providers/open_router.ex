defmodule Trenurang.Matching.Providers.OpenRouter do
  @moduledoc """
  Provider embedding via OpenRouter (openai/text-embedding-3-small).
  Merangkap 2 peran: fallback NLU (di Gateway, belum dibangun) dan
  fallback embedding di sini -- karena Groq tidak punya endpoint embeddings.
  """

  @behaviour Trenurang.Matching.Providers.EmbeddingProvider

  @base_url "https://openrouter.ai/api"
  @model "openai/text-embedding-3-small"

  @impl true
  def embed(text, opts \\ []) when is_binary(text) do
    api_key = Application.get_env(:trenurang_engine, :openrouter_api_key)

    if is_nil(api_key) or api_key == "" do
      {:error, :missing_api_key}
    else
      do_embed(text, api_key, opts)
    end
  end

  defp do_embed(text, api_key, opts) do
    base_opts = [
      base_url: @base_url,
      url: "/v1/embeddings",
      auth: {:bearer, api_key},
      json: %{
        model: @model,
        input: text
      }
    ]

    req_opts = Keyword.merge(base_opts, Keyword.get(opts, :req_options, []))

    case Req.post(req_opts) do
      {:ok, %Req.Response{status: 200, body: %{"data" => [%{"embedding" => values} | _]}}}
      when is_list(values) ->
        {:ok, values}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:unexpected_response, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
