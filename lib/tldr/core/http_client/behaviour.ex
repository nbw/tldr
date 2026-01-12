defmodule Tldr.Core.HttpClient.Behaviour do
  @moduledoc """
  Behaviour for HTTP client operations.
  """

  alias Tldr.Core.HttpClient.Response

  @callback get(url :: String.t()) :: {:ok, Response.t()} | {:error, term()}
  @callback get_cached(url :: String.t(), opts :: keyword()) ::
              {:ok, Req.Response.t()} | {:error, term()}
end
