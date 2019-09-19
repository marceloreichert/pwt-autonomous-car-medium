defmodule AutonomousCar.Scene.Environment do
  use Scenic.Scene

  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  alias AutonomousCar.Math.Vector2
  alias AutonomousCar.Objects.Car

  import Scenic.Primitives

  def init(_arg, opts) do
    viewport = opts[:viewport]

    # Initializes the graph
    graph = Graph.build(theme: :dark)

    # Calculate the transform that centers the car in the viewport
    {:ok, %ViewPort.Status{size: {viewport_width, viewport_height}}} = ViewPort.info(viewport)

    # Initial pos
    {pos_x, pos_y} = { trunc(viewport_width / 2), trunc(viewport_height / 2)}

    # start  timer
    {:ok, timer} = :timer.send_interval(60, :frame)

    state = %{
      viewport: viewport,
      viewport_width: viewport_width,
      viewport_height: viewport_height,
      graph: graph,
      frame_count: 0,
      objects: %{
        car: %{
          dimension: %{ width: 20, height: 10},
          coords: {pos_x, pos_y},
          velocity: {1, 0},
          angle: 0,
          sensor: %{
            left: {0, 0},
            center: {0, 0},
            right: {0, 0}
          }
        },
        goal: %{coords: {20,20}}
      }
    }

    graph = draw_objects(graph, state.objects)

    {:ok, state, push: graph}
  end

def handle_info(:frame, %{frame_count: frame_count} = state) do
  new_state =
    if rem(frame_count, 4) == 0 do
      state |> Car.move
    else
      state
    end

  graph =
    state.graph
    |> draw_objects(state.objects)

  {:noreply, new_state, push: graph}
end

# Keyboard controls
def handle_input({:key, {"left", :press, _}}, _context, state) do
  {:noreply, Car.update_rotation(state, 1)}
end

def handle_input({:key, {"right", :press, _}}, _context, state) do
  {:noreply, Car.update_rotation(state, 2)}
end

def handle_input(_input, _context, state), do: {:noreply, state}

defp draw_objects(graph, object_map) do
  Enum.reduce(object_map, graph, fn {object_type, object_data}, graph ->
    draw_object(graph, object_type, object_data)
 end)
end

defp draw_object(graph, :car, data) do
  {sensor_center_x, sensor_center_y} = data.sensor.center
  {sensor_right_x, sensor_right_y} = data.sensor.right
  {sensor_left_x, sensor_left_y} = data.sensor.left

  %{width: width, height: height} = data.dimension

  {x, y} = data.coords

  angle_radians = data.angle |> Vector2.degrees_to_radians

  new_graph =
    graph
    |> group(fn(g) ->
      g
      |> rect({width, height}, [fill: :white, translate: {x, y}])
      |> circle(4, fill: :red, translate: {x + 22, y - 5}, id: :sensor_left)
      |> circle(4, fill: :green, translate: {x + 28, y + 5}, id: :sensor_center)
      |> circle(4, fill: :blue, translate: {x + 22, y + 15}, id: :sensor_right)
    end, rotate: angle_radians, pin: {x, y}, id: :car)
  end
  defp draw_object(graph, :goal, data) do
    %{coords: coords} = data
    graph
    |> circle(10, fill: :green, translate: coords)
  end
end
