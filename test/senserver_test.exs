defmodule SenserverTest do
  use ExUnit.Case
  doctest Senserver

  test "greets the world" do
    assert Senserver.hello() == :world
  end
end
