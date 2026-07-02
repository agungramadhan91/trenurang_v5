defmodule Trenurang.Matching.Providers.Gemini do
  @moduledoc """
  Provider embedding via Gemini API (gemini-embedding-001, task_type SEMANTIC_SIMILARITY).
  """

  @behaviour Trenurang.Matching.Providers.EmbeddingProvider

  @base_url "https://generativelanguage.googleapis.com/v1beta"
  @model "gemini-embedding-001"

  @impl true
  def embed(text, opts \\ []) when is_binary(text) do
    api_key = Application.get_env(:trenurang_engine, :gemini_api_key)

    if is_nil(api_key) or api_key == "" do
      {:error, :missing_api_key}
    else
      do_embed(text, api_key, opts)
    end
  end

  defp do_embed(text, api_key, opts) do
    base_opts = [
      base_url: @base_url,
      url: "/models/#{@model}:embedContent",
      headers: [{"x-goog-api-key", api_key}],
      json: %{
        content: %{parts: [%{text: text}]},
        taskType: "SEMANTIC_SIMILARITY"
      }
    ]

    req_opts = Keyword.merge(base_opts, Keyword.get(opts, :req_options, []))

    case Req.post(req_opts) do
      {:ok, %Req.Response{status: 200, body: %{"embedding" => %{"values" => values}}}}
      when is_list(values) ->
        {:ok, values}

      {:ok, %Req.Response{status: status, body: body}} ->
        {:error, {:unexpected_response, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
