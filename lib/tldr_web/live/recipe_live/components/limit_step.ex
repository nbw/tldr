defmodule TldrWeb.RecipeLive.Components.LimitStep do
  use TldrWeb, :html

  import TldrWeb.RecipeLive.Components.Helpers

  def step_params_inputs(%{action: "limit"} = assigns) do
    ~H"""
    <div class="bg-gray-50 p-3 rounded">
      <.input
        name={"#{@step_form.name}[params][count]"}
        value={get_param_value(@step_form, "count")}
        type="number"
        label="Count"
        min="1"
      />
    </div>
    """
  end
end
