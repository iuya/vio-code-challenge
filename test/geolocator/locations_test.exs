defmodule Geolocator.LocationsTest do
  use Geolocator.DataCase

  import Mox

  alias Geolocator.Locations
  alias Geolocator.LocationsMock

  describe "locations" do
    alias Geolocator.Locations.Location

    setup :verify_on_exit!

    test "get_location/1 returns the location with given a valid ip_address" do
      ip_address = "35.227.116.242"

      location = %Location{
        ip_address: %Postgrex.INET{address: {35, 227, 116, 242}, netmask: 32},
        country_code: "LR",
        country: "Uganda",
        city: "Port Simoneside",
        latitude: 27.028236306590998,
        longitude: -86.40283568649986,
        mystery_value: 3_227_619_485
      }

      expect(LocationsMock, :get_location, fn ^ip_address -> {:ok, location} end)

      assert {:ok, ^location} = Locations.get_location(ip_address, LocationsMock)
    end

    test "get_location/1 returns bad_request when given an invalid ip_address" do
      ip_address = "this not an ip address"
      expect(LocationsMock, :get_location, fn ^ip_address -> {:error, :bad_request} end)

      assert {:error, :bad_request} = Locations.get_location(ip_address, LocationsMock)
    end

    test "get_location/1 returns not found when the ip_address has no location" do
      ip_address = "127.0.0.1"
      expect(LocationsMock, :get_location, fn ^ip_address -> {:error, :not_found} end)

      assert {:error, :not_found} = Locations.get_location(ip_address, LocationsMock)
    end
  end
end
