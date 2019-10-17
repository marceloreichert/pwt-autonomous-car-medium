defmodule AutonomousCar.NeuralNetwork.Connection do

  alias AutonomousCar.NeuralNetwork.Connection

  defstruct pid: nil, source_pid: nil, target_pid: nil, weight: 0.4

  def start_link(connection_fields \\ %{}) do
    {:ok, pid} = Agent.start_link(fn -> %Connection{} end)
    update(pid, Map.merge(connection_fields, %{pid: pid, weight: :rand.uniform_real}))

    {:ok, pid}
  end

  def get(pid), do: Agent.get(pid, & &1)

  def update(pid, fields) do
    Agent.update(pid, fn connection -> Map.merge(connection, fields) end)
    Agent.update(pid, &Map.merge(&1, fields))
  end

  def connection_for(source_pid, target_pid) do
    {:ok, pid} = start_link()
    pid |> update(%{source_pid: source_pid, target_pid: target_pid})

    {:ok, pid}
  end
end
