defmodule AutonomousCar.NeuralNetwork.Layer do

  alias AutonomousCar.NeuralNetwork.{Layer, Neuron}

  defstruct pid: nil, neurons: []

  def start_link(layer_fields \\ %{}) do
    {:ok, pid} = Agent.start_link(fn -> %Layer{} end)
    neurons = create_neurons(Map.get(layer_fields, :neuron_size))
    pid |> update(%{pid: pid, neurons: neurons})

    {:ok, pid}
  end

  def get(pid), do: Agent.get(pid, & &1)

  def update(pid, fields) do
    Agent.update(pid, &Map.merge(&1, fields))
  end

  defp create_neurons(nil), do: []
  defp create_neurons(size) when size < 1, do: []
  defp create_neurons(size) when size > 0 do
    Enum.into(1..size, [], fn _ ->
      {:ok, pid} = Neuron.start_link()
      pid
    end)
  end

  def add_neurons(layer_pid, neurons) do
    layer_pid |> update(%{neurons: get(layer_pid).neurons ++ neurons})
  end

  def connect(input_layer_pid, output_layer_pid) do
    input_layer = get(input_layer_pid)

    unless contains_bias?(input_layer) do
      {:ok, pid} = Neuron.start_link(%{bias?: true})
      input_layer_pid |> add_neurons([pid])
    end

    for source_neuron <- get(input_layer_pid).neurons,
        target_neuron <- get(output_layer_pid).neurons do
      Neuron.connect(source_neuron, target_neuron)
    end
  end

  defp contains_bias?(layer) do
    Enum.any?(layer.neurons, &Neuron.get(&1).bias?)
  end

  def activate(layer_pid, activation_type, values \\ nil) do
    layer = get(layer_pid)
    values = List.wrap(values)

    layer.neurons
    |> Stream.with_index()
    |> Enum.each(fn tuple ->
      {neuron, index} = tuple
      neuron |> Neuron.activate(activation_type, Enum.at(values, index))
    end)
    layer_pid
  end

  def neurons_output(layer) do
    layer.neurons
    |> Enum.map(&(Neuron.get(&1).output))
  end
end
