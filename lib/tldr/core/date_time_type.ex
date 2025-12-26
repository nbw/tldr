defmodule Tldr.DateTimeType do
  use Ecto.Type

  def type, do: :utc_datetime

  def cast(value) when is_integer(value) do
    DateTime.from_unix(value)
  end

  def cast(%DateTime{} = datetime), do: {:ok, datetime}
  def cast(%NaiveDateTime{} = naive), do: {:ok, DateTime.from_naive!(naive, "Etc/UTC")}

  def cast(value) when is_binary(value) do
    with :error <- try_iso_extended(value),
         :error <- try_unix(value) do
      :error
    else
      {:ok, datetime} -> {:ok, datetime}
    end
  end

  def cast(_), do: :error

  def load(value), do: Ecto.Type.load(:utc_datetime, value)
  def dump(value), do: Ecto.Type.dump(:utc_datetime, value)

  defp try_iso_extended(value) do
    case Timex.parse(value, "{ISO:Extended:Z}") do
      {:ok, datetime} -> {:ok, datetime}
      _ -> :error
    end
  end

  defp try_unix(value) do
    case Integer.parse(value) do
      {timestamp, ""} -> {:ok, DateTime.from_unix(timestamp)}
      _ -> :error
    end
  end
end
