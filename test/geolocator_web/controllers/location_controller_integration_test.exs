defmodule GeolocatorWeb.LocationControllerIntegrationTest do
  use GeolocatorWeb.ConnCase

  alias Geolocator.Locations.Location

  setup %{conn: conn} do
    # In order to avoid using the Mox mocks used by unit tests, we have to change
    # the application config just for these tests
    env = Application.get_env(:geolocator, GeolocatorWeb.LocationController)
    new_env = Keyword.put(env, :locations_service_adapter, Geolocator.Locations)
    Application.put_env(:geolocator, GeolocatorWeb.LocationController, new_env)

    # And we need to leave things as they were before or the unit tests depending
    # on mocks will fail instead.
    on_exit(fn ->
      previous_env = Keyword.put(new_env, :locations_service_adapter, Geolocator.LocationsMock)
      Application.put_env(:geolocator, GeolocatorWeb.LocationController, previous_env)
    end)

    params = %{
      "ip_address" => "35.227.116.242",
      "country_code" => "LR",
      "country" => "Uganda",
      "city" => "Port Simoneside",
      "latitude" => 27.028236306590998,
      "longitude" => -86.40283568649986,
      "mystery_value" => 3_227_619_485
    }

    {:ok, location} =
      %Location{}
      |> Location.changeset(params)
      |> Geolocator.Repo.insert(on_conflict: :replace_all, conflict_target: :ip_address)

    {:ok, %{conn: put_req_header(conn, "accept", "application/json"), location: location}}
  end

  describe "get location - end to end test" do
    test "renders location when ip_address has corresponding location", %{conn: conn} do
      ip_address = "35.227.116.242"

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

      conn = get(conn, ~p"/api/locations/#{ip_address}")
      assert json_response(conn, 404)["errors"] != %{}
    end

    test "renders 400 when ip_address is not a valid ip_address", %{conn: conn} do
      ip_address = "this not an ip address"

      conn = get(conn, ~p"/api/locations/#{ip_address}")
      assert json_response(conn, 400)["errors"] != %{}
    end
  end
end
