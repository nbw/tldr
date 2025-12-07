# defmodule TldrWeb.RecipeLive.Components.LimitStep do
#   use TldrWeb, :html

#   attr :current_action, :string, required: true
#   attr :step_form, :any, required: true
#   # TODO do we need parent name?
#   attr :parent_name, :string, required: true

#   def step(assigns) do
#     ~H"""
#     <div class="border border-gray-300 rounded p-4 relative space-y-3 my-4">
#       <input type="hidden" name={"#{@parent_name}[steps_sort][]"} value={@step_form.index} />
#       <.input field={@step_form[:title]} type="text" label="Step Name" />

#       <.input
#         field={@step_form[:action]}
#         type="select"
#         label="Action"
#         prompt="Select an action..."
#         options={action_options()}
#       />

#       <.step_params_inputs step_form={@step_form} action={@current_action} />
#     </div>
#     """
#   end

#   def action_options do
#     [
#       {"Limit", "limit"},
#       {"Extract", "extract"},
#       {"JSON Get", "json_get"}
#     ]
#   end
# end
