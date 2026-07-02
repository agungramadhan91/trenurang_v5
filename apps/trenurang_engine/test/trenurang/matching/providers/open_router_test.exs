defmodule Trenurang.Matching.Providers.OpenRouterTest do
  use ExUnit.Case, async: true

  alias Trenurang.Matching.Providers.OpenRouter

  @stub_opts [req_options: [plug: {Req.Test, OpenRouter}]]

  setup do
    Application.put_env(:trenurang_engine, :openrouter_api_key, "test-api-key")

    on_exit(fn ->
      Application.delete_env(:trenurang_engine, :openrouter_api_key)
    end)

    :ok
  end

  test "embed/2 berhasil, mengembalikan {:ok, [float]} dari response OpenRouter" do
    Req.Test.stub(OpenRouter, fn conn ->
      Req.Test.json(conn, %{"data" => [%{"embedding" => [0.1, 0.2, 0.3], "index" => 0}]})
    end)

    assert {:ok, [0.1, 0.2, 0.3]} = OpenRouter.embed("teks contoh", @stub_opts)
  end

  test "embed/2 kirim request ke path, header, & body yang benar" do
    Req.Test.stub(OpenRouter, fn conn ->
      assert conn.request_path == "/api/v1/embeddings"
      assert Plug.Conn.get_req_header(conn, "authorization") == ["Bearer test-api-key"]

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      decoded = Jason.decode!(body)

      assert decoded["model"] == "openai/text-embedding-3-small"
      assert decoded["input"] == "teks contoh"

      Req.Test.json(conn, %{"data" => [%{"embedding" => [0.5], "index" => 0}]})
    end)

    assert {:ok, [0.5]} = OpenRouter.embed("teks contoh", @stub_opts)
  end

  test "embed/2 mengembalikan error kalau response status bukan 200" do
    Req.Test.stub(OpenRouter, fn conn ->
      Plug.Conn.send_resp(conn, 429, Jason.encode!(%{"error" => "rate limited"}))
    end)

    assert {:error, {:unexpected_response, 429, _body}} = OpenRouter.embed("teks contoh", @stub_opts)
  end

  test "embed/2 mengembalikan error kalau koneksi gagal (transport error)" do
    Req.Test.stub(OpenRouter, fn conn ->
      Req.Test.transport_error(conn, :econnrefused)
    end)

    assert {:error, %Req.TransportError{}} = OpenRouter.embed("teks contoh", @stub_opts)
  end

  test "embed/2 mengembalikan {:error, :missing_api_key} kalau api key nil" do
    Application.put_env(:trenurang_engine, :openrouter_api_key, nil)

    assert {:error, :missing_api_key} = OpenRouter.embed("teks contoh", @stub_opts)
  end
end
