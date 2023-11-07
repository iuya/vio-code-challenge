defmodule GeolocatorWeb.LocationControllerTest do
  use GeolocatorWeb.ConnCase

  import Mox

  alias Geolocator.Locations.Location
  alias Geolocator.LocationsMock

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  setup :verify_on_exit!

  describe "get location" do
    test "renders location when ip_address has corresponding location", %{conn: conn} do
      ip_address = "35.227.116.242"

      expect(LocationsMock, :get_location, fn ^ip_address ->
        {:ok,
         %Location{
           ip_address: %Postgrex.INET{address: {35, 227, 116, 242}, netmask: 32},
           country_code: "LR",
           country: "Uganda",
           city: "Port Simoneside",
           latitude: 27.028236306590998,
           longitude: -86.40283568649986,
           mystery_value: 3_227_619_485
         }}
      end)

      conn = get(conn, ~p"/api/locations/#{ip_address}")

      assert %{
               "ip_address" => ^ip_address,
               "country_code" => "LR",
               "country" => "Uganda",
               "city" => "Port Simoneside",
               "latitude" => 27.028236306590998,
               "longitude" => -86.40283568649986,
               "mystery_value" => 3_227_619_485
             } = json_response(conn, 200)
    end

    test "renders 404 error when ip_address does not have corresponding location", %{conn: conn} do
      ip_address = "127.0.0.1"
      expect(LocationsMock, :get_location, fn ^ip_address -> {:error, :not_found} end)

      conn = get(conn, ~p"/api/locations/#{ip_address}")
      assert json_response(conn, 404)["errors"] != %{}
    end

    test "renders 400 when ip_address is not a valid ip_address", %{conn: conn} do
      ip_address = "this not an ip address"
      expect(LocationsMock, :get_location, fn ^ip_address -> {:error, :bad_request} end)

      conn = get(conn, ~p"/api/locations/#{ip_address}")
      assert json_response(conn, 400)["errors"] != %{}
    end
  end
end
