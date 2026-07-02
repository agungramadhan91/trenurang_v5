defmodule Trenurang.Matching.Providers.GeminiTest do
  use ExUnit.Case, async: true

  alias Trenurang.Matching.Providers.Gemini

  @stub_opts [req_options: [plug: {Req.Test, Gemini}]]

  setup do
    # Pastikan API key ter-set selama test, tidak bergantung isi .env asli developer
    Application.put_env(:trenurang_engine, :gemini_api_key, "test-api-key")

    on_exit(fn ->
      Application.delete_env(:trenurang_engine, :gemini_api_key)
    end)

    :ok
  end

  test "embed/2 berhasil, mengembalikan {:ok, [float]} dari response Gemini" do
    Req.Test.stub(Gemini, fn conn ->
      Req.Test.json(conn, %{"embedding" => %{"values" => [0.1, 0.2, 0.3]}})
    end)

    assert {:ok, [0.1, 0.2, 0.3]} = Gemini.embed("teks contoh", @stub_opts)
  end

  test "embed/2 kirim request ke path & body yang benar" do
    Req.Test.stub(Gemini, fn conn ->
      assert conn.request_path == "/v1beta/models/gemini-embedding-001:embedContent"
      assert Plug.Conn.get_req_header(conn, "x-goog-api-key") == ["test-api-key"]

      {:ok, body, conn} = Plug.Conn.read_body(conn)
      decoded = Jason.decode!(body)

      assert decoded["content"]["parts"] == [%{"text" => "teks contoh"}]
      assert decoded["taskType"] == "SEMANTIC_SIMILARITY"

      Req.Test.json(conn, %{"embedding" => %{"values" => [0.5]}})
    end)

    assert {:ok, [0.5]} = Gemini.embed("teks contoh", @stub_opts)
  end

  test "embed/2 mengembalikan error kalau response status bukan 200" do
    Req.Test.stub(Gemini, fn conn ->
      Plug.Conn.send_resp(conn, 429, Jason.encode!(%{"error" => "rate limited"}))
    end)

    assert {:error, {:unexpected_response, 429, _body}} = Gemini.embed("teks contoh", @stub_opts)
  end

  test "embed/2 mengembalikan error kalau koneksi gagal (transport error)" do
    Req.Test.stub(Gemini, fn conn ->
      Req.Test.transport_error(conn, :econnrefused)
    end)

    assert {:error, %Req.TransportError{}} = Gemini.embed("teks contoh", @stub_opts)
  end

  test "embed/2 mengembalikan {:error, :missing_api_key} kalau api key nil" do
    Application.put_env(:trenurang_engine, :gemini_api_key, nil)

    assert {:error, :missing_api_key} = Gemini.embed("teks contoh", @stub_opts)
  end
end
