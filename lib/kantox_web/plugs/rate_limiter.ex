defmodule KantoxWeb.Plugs.RateLimiter do
  @moduledoc """
  Rate limiter plug to prevent API abuse and protect against DoS attacks.
  
  Limits requests per IP address using Hammer.
  """
  
  import Plug.Conn
  require Logger

  @requests_per_second 100
  @interval_ms 1_000

  def init(opts), do: opts

  def call(conn, _opts) do
    key = get_rate_limit_key(conn)
    
    case Hammer.check_rate(key, @interval_ms, @requests_per_second) do
      {:allow, count} ->
        conn
        |> put_resp_header("x-ratelimit-limit", "#{@requests_per_second}")
        |> put_resp_header("x-ratelimit-remaining", "#{@requests_per_second - count}")
        |> put_resp_header("x-ratelimit-reset", "#{@interval_ms}")

      {:deny, _limit} ->
        Logger.warning("Rate limit exceeded for #{key}")
        
        conn
        |> put_status(:too_many_requests)
        |> put_resp_header("retry-after", "1")
        |> Phoenix.Controller.json(%{
          error: "Rate limit exceeded. Please try again later.",
          retry_after_seconds: 1
        })
        |> halt()
    end
  end

  defp get_rate_limit_key(conn) do
    # Rate limit by IP address
    ip = conn.remote_ip |> :inet.ntoa() |> to_string()
    "basket:#{ip}"
  end
end

