defmodule TldrWeb.Layouts do
  @moduledoc """
  This module holds layouts and related functionality
  used by your application.
  """
  use TldrWeb, :html

  # Embed all files in layouts/* within this module.
  # The default root.html.heex file contains the HTML
  # skeleton of your application, namely HTML headers
  # and other static content.
  embed_templates "layouts/*"

  @doc """
  Renders your app layout.

  This function is typically invoked from every template,
  and it often contains your application menu, sidebar,
  or similar.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr :flash, :map, required: true, doc: "the map of flash messages"

  attr :current_scope, :map,
    default: nil,
    doc: "the current [scope](https://hexdocs.pm/phoenix/scopes.html)"

  slot :inner_block, required: true

  def landing(assigns) do
    ~H"""
    <header class="px-4 sm:px-6 lg:px-8 py-3">
      <nav class="flex items-center justify-end gap-6 text-sm text-base-content/60">
        <%= if @current_scope do %>
          <.link href={~p"/feed"} class="hover:text-base-content transition-colors tracking-wide">
            Feed
          </.link>
          <.link href={~p"/recipes"} class="hover:text-base-content transition-colors tracking-wide">
            Recipes
          </.link>
          <.link href={~p"/users/settings"} class="hover:text-base-content transition-colors tracking-wide">
            Settings
          </.link>
          <.link href={~p"/users/log-out"} method="delete" class="hover:text-base-content transition-colors tracking-wide">
            Log out
          </.link>
        <% else %>
          <.link href={~p"/users/register"} class="hover:text-base-content transition-colors tracking-wide">
            Register
          </.link>
          <.link href={~p"/users/log-in"} class="hover:text-base-content transition-colors tracking-wide">
            Log in
          </.link>
        <% end %>
        <.theme_toggle />
      </nav>
    </header>

    <main class="relative">
      {render_slot(@inner_block)}
    </main>

    <.flash_group flash={@flash} />
    """
  end

  attr :class, :string, default: ""
  def app(assigns) do
    ~H"""
    <header class={["px-4 sm:px-6 lg:px-8 py-3", @class]}>
      <nav class="flex items-center justify-end gap-6 text-sm text-base-content/60">
        <%= if @current_scope do %>
          <.link href={~p"/feed"} class="hover:text-base-content transition-colors tracking-wide">
            Feed
          </.link>
          <.link href={~p"/recipes"} class="hover:text-base-content transition-colors tracking-wide">
            Recipes
          </.link>
          <.link href={~p"/users/settings"} class="hover:text-base-content transition-colors tracking-wide">
            Settings
          </.link>
          <.link href={~p"/users/log-out"} method="delete" class="hover:text-base-content transition-colors tracking-wide">
            Log out
          </.link>
        <% else %>
          <.link href={~p"/users/register"} class="hover:text-base-content transition-colors tracking-wide">
            Register
          </.link>
          <.link href={~p"/users/log-in"} class="hover:text-base-content transition-colors tracking-wide">
            Log in
          </.link>
        <% end %>
        <.theme_toggle />
      </nav>
    </header>

    <main class={["relative px-4 sm:px-6 lg:px-8", @class]}>
      <div class="mx-auto max-w-4xl space-y-4">
        {render_slot(@inner_block)}
      </div>
    </main>

    <.flash_group flash={@flash} />
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        {gettext("Attempting to reconnect")}
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.

  See <head> in root.html.heex which applies the theme before page load.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="relative flex flex-row items-center bg-base-300/50 rounded-sm">
      <div class="absolute w-1/3 h-full rounded-sm bg-base-content/10 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left] duration-200" />

      <button
        class="flex p-1.5 cursor-pointer w-1/3 relative z-10"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-3.5 opacity-50 hover:opacity-100 transition-opacity" />
      </button>

      <button
        class="flex p-1.5 cursor-pointer w-1/3 relative z-10"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-3.5 opacity-50 hover:opacity-100 transition-opacity" />
      </button>

      <button
        class="flex p-1.5 cursor-pointer w-1/3 relative z-10"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-3.5 opacity-50 hover:opacity-100 transition-opacity" />
      </button>
    </div>
    """
  end
end
