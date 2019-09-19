defmodule AutonomousCar.Objects.Car do

  alias AutonomousCar.Math.Vector2

  def move(%{objects: %{car: car}} = state) do
    new_pos = Vector2.add(car.coords, car.velocity)
    rotated = Vector2.rotate({10,0}, car.angle)
    new_coords = Vector2.add(rotated, new_pos)

    state
    |> put_in([:objects, :car, :coords], new_coords)
  end

  def update_rotation(state, action) do
    rotation = action?(action)
    put_in(state, [:objects, :car, :angle], state.objects.car.angle + rotation)
  end

  defp action?(0), do: 0
  defp action?(1), do: -20
  defp action?(2), do: 20
end
