defmodule Senserver.I2CDevice.AHT20 do
  use Bitwise

  require Logger

  alias Senserver.I2CBusController

  @address 0x38
  @init_cmd <<0xBE, 0x08, 0x00>>
  @read_cmd <<0xAC, 0x33, 0x00>>

  def measure() do
    GenServer.call(I2CBusController, {:process_call, {__MODULE__, :measure, [@address]}})
  end

  def measure(ref, address) do
    with :ok <- write(ref, address, @init_cmd),
         :ok <- write(ref, address, @read_cmd),
         {:ok, {temperature, humidity}} <- read_values(ref, address) do
      {temperature, humidity}
    else
      {:error, term} ->
        Logger.error(inspect(term))
        {-274, -1}
    end
  end

  defp write(ref, address, command) do
    ret = Circuits.I2C.write(ref, address, command)

    Process.sleep(100)
    ret
  end

  defp read_values(ref, address) do
    ret =
      case Circuits.I2C.read(ref, address, _read_bytes = 7) do
        {:ok, values} -> {:ok, {_temperature, _humidity} = to_physical(values)}
        {:error, term} -> {:error, term}
      end

    Process.sleep(100)
    ret
  end

  defp to_physical(values) do
    <<_, h1, h2, ht3, t4, t5, _>> = values

    raw_h = h1 <<< 12 ||| h2 <<< 4 ||| ht3 >>> 4
    h = Float.round(raw_h / :math.pow(2, 20) * 100.0, 1)

    raw_t = (ht3 &&& 0x0F) <<< 16 ||| t4 <<< 8 ||| t5
    t = Float.round(raw_t / :math.pow(2, 20) * 200.0 - 50.0, 1)

    {t, h}
  end
end
