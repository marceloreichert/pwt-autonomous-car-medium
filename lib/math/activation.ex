defmodule AutonomousCar.Math.Activation do

  def calculate_output(input, :softmax), do: softmax(input)
  def calculate_output(input, :sigmoid), do: sigmoid(input)
  def calculate_output(input, :relu), do: relu(input)

  defp softmax([input]), do: softmax(input)
  defp softmax(input) do
    max_input = Enum.max(input)
    x = Enum.map(input, fn(y) -> y-max_input end)
    sum = listsum(x)
    Enum.map(x, fn(y) -> :math.exp(y)/sum end)
  end

  defp listsum([]), do: 0
  defp listsum([x|xs]), do: :math.exp(x) + listsum(xs)

  defp sigmoid(input), do: 1 / (1 + :math.exp(-input))

  defp relu(input) when input <= 0, do: 0
  defp relu(input) when input > 0, do: input
end
