defmodule TldrWeb.CustomIcons do
  @moduledoc false

  use Phoenix.Component
  use Gettext, backend: TldrWeb.Gettext

  attr :class, :string, default: ""
  attr :fill, :string, default: "fill-none"
  @spec icon_heart(map()) :: Phoenix.LiveView.Rendered.t()
  def icon_heart(assigns) do
    ~H"""
    <svg class={[@class, @fill]} xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
      <g
        stroke-linejoin="round"
        stroke-linecap="round"
        stroke-width="1.5"
        stroke="currentColor"
      >
        <path d="M19 14c1.49-1.46 3-3.21 3-5.5A5.5 5.5 0 0 0 16.5 3c-1.76 0-3 .5-4.5 2-1.5-1.5-2.74-2-4.5-2A5.5 5.5 0 0 0 2 8.5c0 2.3 1.5 4.05 3 5.5l7 7Z">
        </path>
      </g>
    </svg>
    """
  end
end
