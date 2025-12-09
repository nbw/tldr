# defmodule TldrWeb.RecipeLive.Components.LimitStep do
#   use TldrWeb, :html

#   attr :current_action, :string, required: true
#   attr :step_form, :any, required: true
#   # TODO do we need parent name?
#   attr :parent_name, :string, required: true

#   def step(assigns) do
#     ~H"""
#     <div class="p-3 rounded">
#       <p class="text-sm text-base-content/70 mb-3">
#         {render_slot(@description)}
#       </p>
#       <div class="space-y-2 mb-3">
#         {render_slot(@description)}
#         <% fields = get_extract_fields(@step_form) %>
#         <%= if fields == [] do %>
#           <p class="text-sm text-base-content/70 italic">No fields configured yet.</p>
#         <% else %>
#           <div :for={{idx, %{"key" => key, "value" => value}} <- fields}>
#             <div class="flex gap-2 items-center p-2 rounded border border-gray-200">
#               <input
#                 type="text"
#                 name={"#{@step_form.name}[params][fields][#{idx}][key]"}
#                 value={key}
#                 placeholder="Field name"
#                 class="flex-1 px-2 py-1 border border-gray-300 rounded text-sm"
#               />
#               <span class="text-base-content/50">→</span>
#               <input
#                 type="text"
#                 name={"#{@step_form.name}[params][fields][#{idx}][value]"}
#                 value={value}
#                 placeholder="JSON path (e.g., $.title)"
#                 class="flex-1 px-2 py-1 border border-gray-300 rounded text-sm"
#               />
#               <button
#                 type="button"
#                 phx-click="step-extract:remove_extract_field"
#                 phx-value-id={step_id(@step_form)}
#                 phx-value-idx={idx}
#                 class="text-red-600 hover:text-red-800 text-sm"
#               >
#                 <.icon name="hero-trash" class="w-4 h-4" />
#               </button>
#             </div>
#           </div>
#         <% end %>
#       </div>

#       <button
#         type="button"
#         phx-click="step-extract:add_extract_field"
#         phx-value-id={step_id(@step_form)}
#         phx-value-index={step_index(@step_form)}
#         class="block w-full border border-emerald-400 bg-emerald-100 rounded p-2 text-emerald-700 text-center text-sm hover:bg-emerald-200"
#       >
#         <.icon name="hero-plus-circle" class="w-4 h-4" /> Add field
#       </button>
#     </div>
#     """
#   end
# end
