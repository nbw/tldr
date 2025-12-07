defmodule TldrWeb.RecipeLive.Components.JsonGetStep do
  use TldrWeb, :html

  import TldrWeb.RecipeLive.Components.Helpers

  def step_params_inputs(%{action: "json_get"} = assigns) do
    ~H"""
    <div class="bg-gray-50 p-3 rounded">
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
