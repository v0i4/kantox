defmodule KantoxWeb.HealthControllerTest do
  use KantoxWeb.ConnCase

  describe "GET /" do
    test "returns health status from root", %{conn: conn} do
      conn = get(conn, ~p"/")

      response = json_response(conn, 200)

      assert response["status"] == "ok"
      assert response["service"] == "Kantox API"
      assert Map.has_key?(response, "timestamp")
    end
  end

  describe "GET /api/health" do
    test "returns health status", %{conn: conn} do
      conn = get(conn, ~p"/api/health")

      response = json_response(conn, 200)

      assert response["status"] == "ok"
      assert response["service"] == "Kantox API"
      assert Map.has_key?(response, "timestamp")
    end

    test "timestamp is a valid datetime", %{conn: conn} do
      conn = get(conn, ~p"/api/health")

      response = json_response(conn, 200)
      timestamp = response["timestamp"]

      # Verify it's a valid ISO8601 datetime string
      assert is_binary(timestamp)
      assert String.contains?(timestamp, "T")
      assert String.contains?(timestamp, "Z")
    end
  end
end

