defmodule Senserver.I2CBusController do
  use GenServer

  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def process_call({m, f, a}) do
    GenServer.call(__MODULE__, {:process_call, {m, f, a}})
  end

  @impl GenServer
  def init(state) do
    Logger.info("|=====> Starting #{__MODULE__} GenServer")

    bus_name = Keyword.fetch!(state, :bus_name)
    {:ok, bus} = Circuits.I2C.open(bus_name)

    {:ok, _state = %{bus: bus}}
  end

  @impl GenServer
  def terminate(reason, state) do
    Logger.error("|=====> Stopping #{__MODULE__} GenServer, reason: #{inspect(reason)}")

    Circuits.I2C.close(state.bus)
  end

  @impl GenServer
  def handle_call({:process_call, {m, f, a}}, _from, state) do
    {:reply, apply(m, f, [state.bus | a]), state}
  end
end
