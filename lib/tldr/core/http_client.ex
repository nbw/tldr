defmodule Tldr.Core.HttpClient do
  @moduledoc false

  def get(url) do
    case Req.get(url) do
      {:ok, response} -> {:ok, response.body}
      {:error, error} -> {:error, error}
    end
  end

  @cache_ttl 600

  def get_cached(url) do
    case Cachex.get(:tldr, url) do
      {:ok, nil} ->
        Req.get(url)
        |> tap(fn
          {:ok, body} -> Cachex.put(:tldr, url, body, ttl: @cache_ttl)
          _ -> nil
        end)

      {:ok, value} ->
        {:ok, value}


      {:error, error} ->
        {:error, error}
    end
  end
end
