defmodule KantoxWeb.Plugs.RateLimiterTest do
  use KantoxWeb.ConnCase

  alias KantoxWeb.Plugs.RateLimiter

  setup do
    # Clear rate limit state by using unique keys per test
    # Hammer doesn't provide a clean delete function, so we'll use unique IPs
    :ok
  end

  describe "RateLimiter" do
    test "allows requests under the limit", %{conn: conn} do
      # Use a unique IP for this test
      conn = %{conn | remote_ip: {127, 0, 0, 1}}

      # Make 50 requests (well under 100/second limit)
      results =
        Enum.map(1..50, fn _ ->
          conn
          |> RateLimiter.call([])
          |> Map.get(:halted)
        end)

      # All should be allowed
      assert Enum.all?(results, &(&1 == false))
    end

    test "denies requests over the limit", %{conn: conn} do
      # Use a unique IP for this test
      conn = %{conn | remote_ip: {127, 0, 0, 2}}

      # Make 101 requests (over 100/second limit)
      results =
        Enum.map(1..101, fn _ ->
          conn
          |> RateLimiter.call([])
          |> then(fn conn ->
            %{halted: conn.halted, status: conn.status}
          end)
        end)

      # First 100 should pass
      allowed = Enum.take(results, 100)
      assert Enum.all?(allowed, &(&1.halted == false))

      # 101st should be denied
      denied = Enum.at(results, 100)
      assert denied.halted == true
      assert denied.status == 429
    end

    test "adds rate limit headers to response", %{conn: conn} do
      # Use a unique IP for this test
      conn = %{conn | remote_ip: {127, 0, 0, 3}}

      conn = RateLimiter.call(conn, [])

      assert Plug.Conn.get_resp_header(conn, "x-ratelimit-limit") == ["100"]
      assert Plug.Conn.get_resp_header(conn, "x-ratelimit-reset") == ["1000"]
      
      remaining = Plug.Conn.get_resp_header(conn, "x-ratelimit-remaining")
      assert length(remaining) == 1
      [remaining_value] = remaining
      assert String.to_integer(remaining_value) in 0..100
    end

    test "returns proper error message when rate limited", %{conn: conn} do
      # Use a unique IP for this test
      conn = %{conn | remote_ip: {127, 0, 0, 4}}

      # Exhaust the rate limit
      Enum.each(1..100, fn _ ->
        RateLimiter.call(conn, [])
      end)

      # Next request should be denied
      conn = RateLimiter.call(conn, [])

      assert conn.status == 429
      assert conn.halted == true
      assert Plug.Conn.get_resp_header(conn, "retry-after") == ["1"]
    end

    test "rate limits are per IP address", %{conn: conn} do
      conn1 = %{conn | remote_ip: {127, 0, 0, 5}}
      conn2 = %{conn | remote_ip: {127, 0, 0, 6}}

      # Exhaust limit for IP1
      Enum.each(1..100, fn _ ->
        RateLimiter.call(conn1, [])
      end)

      # IP1 should be rate limited
      result1 = RateLimiter.call(conn1, [])
      assert result1.halted == true
      assert result1.status == 429

      # IP2 should still be allowed
      result2 = RateLimiter.call(conn2, [])
      assert result2.halted == false
    end
  end
end

