defmodule Geolocator.Locations.Adapter.Test do
  @moduledoc """
  Test the default adapter
  """
  use Geolocator.DataCase

  alias Geolocator.Locations
  alias Geolocator.LocationsFixtures

  setup do
    LocationsFixtures.location_fixture(%{
      "ip_address" => "35.227.116.242",
      "country_code" => "LR",
      "country" => "Uganda",
      "city" => "Port Simoneside",
      "latitude" => 27.028236306590998,
      "longitude" => -86.40283568649986,
      "mystery_value" => 3_227_619_485
    })
  end

  describe "locations" do
    test "get_location/1 returns the location with given a valid ip_address", %{
      location: location
    } do
      ip_address = location.ip_address

      assert {:ok, ^location} = Locations.get_location(ip_address)
    end

    test "get_location/1 returns bad_request when given an invalid ip_address" do
      ip_address = "this not an ip address"
      assert {:error, :bad_request} = Locations.get_location(ip_address)
    end

    test "get_location/1 returns not found when the ip_address has no location" do
      ip_address = "127.0.0.1"

      assert {:error, :not_found} = Locations.get_location(ip_address)
    end
  end
end
