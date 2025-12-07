defmodule Tldr.DateTimeType do
  use Ecto.Type

  def type, do: :utc_datetime

  def cast(value) when is_integer(value) do
    DateTime.from_unix(value)
  end

  def cast(%DateTime{} = datetime), do: {:ok, datetime}
  def cast(%NaiveDateTime{} = naive), do: {:ok, DateTime.from_naive!(naive, "Etc/UTC")}

  def cast(value) when is_binary(value) do
    case Integer.parse(value) do
      {timestamp, ""} -> DateTime.from_unix(timestamp)
      _ -> :error
    end
  end

  def cast(_), do: :error

  def load(value), do: Ecto.Type.load(:utc_datetime, value)
  def dump(value), do: Ecto.Type.dump(:utc_datetime, value)
end
