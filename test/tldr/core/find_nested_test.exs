# TODO: probably delete

# defmodule Tldr.Core.FindNestedTest do
#   use Tldr.DataCase

#   alias Tldr.Kitchen.Step
#   alias Tldr.Core.FindNested

#   describe "find" do
#     test "find top level" do
#       step = %Step{id: 1}
#       steps = [step]

#       assert step == FindNested.find(steps, :id, 1, :steps)
#       assert nil == FindNested.find(steps, :id, 2, :steps)
#     end

#     test "find nested" do
#       nested_step = %Step{id: 3}
#       step = %Step{id: 1, steps: [nested_step]}
#       steps = [step]

#       assert nested_step == FindNested.find(steps, :id, 3, :steps)
#     end
#   end

#   describe "update" do
#     test "update top level" do
#       step = %Step{id: 1, title: "Test"}
#       new_step_params = %{title: "Test again"}
#       steps = [step]

#       {[updated_step], true} =
#         FindNested.update(steps, :id, 1, :steps, fn struct ->
#           Map.merge(struct, new_step_params)
#         end)

#       assert updated_step.title == "Test again"
#     end

#     test "update nested" do
#       nested_step = %Step{id: 3, title: "Nested"}
#       new_step_params = %{title: "Nested 1234"}
#       step = %Step{id: 1}
#       steps = [step, %Step{id: 2}]

#       {[updated_step, other_step], true} =
#         FindNested.update(steps, :id, 3, :steps, fn struct ->
#           Map.merge(struct, new_step_params)
#         end)

#       assert other_step.id == 2

#       nested_updated_step = updated_step.steps |> List.first()

#       assert nested_updated_step.title == "Nested 1234"

#       IO.inspect(updated_step)
#     end
#   end
# end
