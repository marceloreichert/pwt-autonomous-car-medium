defmodule AutonomousCar.NeuralNetwork.Network do
  alias AutonomousCar.NeuralNetwork.{Layer, Network, Neuron}
  alias AutonomousCar.Math.Activation

  defstruct pid: nil, input_layer: nil, hidden_layers: [], output_layer: nil, error: 0

  def start_link(layer_sizes \\ []) do
    {:ok, pid} = Agent.start_link(fn -> %Network{} end)

    layers =
      map_layers(
        input_neurons(layer_sizes),
        hidden_neurons(layer_sizes),
        output_neurons(layer_sizes)
      )

    pid |> update_layers(layers)
    pid |> connect_layers
    {:ok, pid}
  end

  def get(pid), do: Agent.get(pid, & &1)

  def update_layers(pid, layers) do
    layers = Map.merge(layers, %{pid: pid})
    Agent.update(pid, &Map.merge(&1, layers))
  end

  def predict(network, input_values) do
    network.input_layer
    |> Layer.activate(:relu, input_values)

    Enum.each(network.hidden_layers, fn hidden_layer ->
      hidden_layer
      |> Layer.activate(:relu)
    end)

    network.output_layer
    |> Layer.activate(:sigmoid)

    prob_actions =
      network.output_layer
      |> Layer.get()
      |> Layer.neurons_output()
      |> Activation.calculate_output(:softmax)

    action =
      prob_actions
      |> Enum.find_index(fn value -> Enum.max(prob_actions) == value end)
  end

  defp input_neurons(layer_sizes) do
    size = layer_sizes |> List.first()
    {:ok, pid} = Layer.start_link(%{neuron_size: size})
    pid
  end

  defp hidden_neurons(layer_sizes) do
    layer_sizes
    |> hidden_layer_slice
    |> Enum.map(fn size ->
      {:ok, pid} = Layer.start_link(%{neuron_size: size})
      pid
    end)
  end

  defp output_neurons(layer_sizes) do
    size = layer_sizes |> List.last()
    {:ok, pid} = Layer.start_link(%{neuron_size: size})
    pid
  end

  defp hidden_layer_slice(layer_sizes) do
    layer_sizes
    |> Enum.slice(1..(length(layer_sizes) - 2))
  end

  defp connect_layers(pid) do
    layers =
      pid
      |> Network.get()
      |> flatten_layers

    layers
    |> Stream.with_index()
    |> Enum.each(fn tuple ->
      {layer, index} = tuple
      next_index = index + 1

      if Enum.at(layers, next_index) do
        Layer.connect(layer, Enum.at(layers, next_index))
      end
    end)
  end

  defp flatten_layers(network) do
    [network.input_layer] ++ network.hidden_layers ++ [network.output_layer]
  end

  defp map_layers(input_layer, hidden_layers, output_layer) do
    %{
      input_layer: input_layer,
      output_layer: output_layer,
      hidden_layers: hidden_layers
    }
  end
end
