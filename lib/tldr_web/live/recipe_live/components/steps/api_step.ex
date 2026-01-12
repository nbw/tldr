defmodule TldrWeb.RecipeLive.Components.ApiStep do
  use TldrWeb, :html

  import TldrWeb.RecipeLive.Components.Helpers

  use TldrWeb.RecipeLive.Components.StepComponent

  def step_params_inputs(%{action: "api"} = assigns) do
    ~H"""
    <div class="p-3 rounded">
      <.input
        name={"#{@step_form.name}[params][method]"}
        value={get_param_value(@step_form, "method") || "GET"}
        type="text"
        label="Method"
        placeholder="GET / POST / etc."
        readonly
      />
      <.input
        name={"#{@step_form.name}[params][url]"}
        value={get_param_value(@step_form, "url")}
        type="text"
        label="URL"
        placeholder="https://api.example.com/data or use {{val}} for interpolation"
      />
    </div>
    """
  end
end
