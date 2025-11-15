defmodule Tldr.Repo do
  use Ecto.Repo,
    otp_app: :tldr,
    adapter: Ecto.Adapters.SQLite3
end
