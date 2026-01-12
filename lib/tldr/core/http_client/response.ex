defmodule Tldr.Core.HttpClient.Response do
  @moduledoc """
  A response from the HTTP client. It also contains the URL that was requested.
  """

  @derive {JSON.Encoder, only: [:status, :body, :content_type, :url]}

  defstruct [:status, :body, :content_type, :url]

  def new(%Req.Response{status: status, body: body} = response, url) do
    %__MODULE__{
      status: status,
      content_type: get_content_type(response),
      body: body,
      url: url
    }
  end

  def get_content_type(response) do
    Req.Response.get_header(response, "content-type") |> List.first()
  end
end
