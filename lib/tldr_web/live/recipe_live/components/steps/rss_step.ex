defmodule TldrWeb.RecipeLive.Components.RssStep do
  use TldrWeb, :html
  use TldrWeb.RecipeLive.Components.StepComponent

  def step_params_inputs(%{action: "rss"} = assigns) do
    ~H"""
    <div class="p-3 rounded">
      <p class="text-sm text-base-content/70 mb-3">
        Parse RSS feed into a structured format.
      </p>
    </div>
    """
  end
end
