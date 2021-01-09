defmodule Senserver.I2CDevice.S300 do
  use Bitwise

  require Logger

  alias Senserver.I2CBusController

  @address 0x31
  @read_cmd <<0x52>>

  def measure() do
    GenServer.call(I2CBusController, {:process_call, {__MODULE__, :measure, [@address]}})
  end

  def measure(ref, address) do
    with :ok <- write(ref, address, @read_cmd),
         {:ok, ppm} <- read_co2(ref, address) do
      ppm
    else
      {:error, term} ->
        Logger.error(inspect(term))
        -1
    end
  end

  defp write(ref, address, command) do
    ret = Circuits.I2C.write(ref, address, command)

    Process.sleep(10)
    ret
  end

  defp read_co2(ref, address) do
    ret =
      case Circuits.I2C.read(ref, address, _read_bytes = 7) do
        {:ok, <<8, h, l, _, _, _, _>>} -> {:ok, _ppm = (h <<< 8) + l}
        {:ok, <<255, _, _, _, _, _, _>>} -> {:error, "invalid value"}
        {:error, term} -> {:error, term}
      end

    Process.sleep(10)
    ret
  end
end
