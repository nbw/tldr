defmodule Tldr.Core.HttpClient do
  @moduledoc false

  @behaviour Tldr.Core.HttpClient.Behaviour

  alias Tldr.Core.HttpClient.Response

  @impl true
  def get(url) do
    case Req.get(url) do
      {:ok, response} -> {:ok, Response.new(response, url)}
      {:error, error} -> {:error, error}
    end
  end

  @cache_ttl 600

  @impl true
  def get_cached(url, opts \\ []) do
    require_json = Keyword.get(opts, :require_json, false)

    case Cachex.get(:tldr, url) do
      {:ok, nil} ->
        get(url)
        |> tap(fn
          {:ok, %{status: 200} = response} when require_json ->
            # if we expect JSON and the response is not JSON, don't cache it.
            if is_json?(response) do
              Cachex.put(:tldr, url, response, ttl: @cache_ttl)
            end

          {:ok, %{status: 200} = response} ->
            Cachex.put(:tldr, url, response, ttl: @cache_ttl)

          _ ->
            nil
        end)

      {:ok, value} ->
        {:ok, value}

      {:error, error} ->
        {:error, error}
    end
  end

  defp is_json?(%Response{content_type: content_type}) do
    is_binary(content_type) and String.starts_with?(content_type, "application/json")
  end
end
