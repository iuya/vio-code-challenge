defmodule Geolocator.Loader.StatsTest do
  @moduledoc """
  Tests for the Geolocator.Loader.Stats module
  """

  use ExUnit.Case

  alias Geolocator.Loader.Stats

  test "successfull creation of Stats struct" do
    assert %Stats{
             total: 600,
             accepted: 500,
             discarded: 100,
             elapsed_time_ms: 1000
           } = Stats.new(500, 100, 1000)
  end
end
