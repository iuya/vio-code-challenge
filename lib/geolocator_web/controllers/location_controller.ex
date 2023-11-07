defmodule GeolocatorWeb.LocationController do
  use GeolocatorWeb, :controller

  alias Geolocator.Locations

  action_fallback GeolocatorWeb.FallbackController

  def show(conn, %{"ip_address" => ip_address}) do
    with {:ok, location} <-
           Locations.get_location(ip_address, location_service_adapter()) do
      render(conn, "show.json", location: location)
    end
  end

  def location_service_adapter() do
    Application.get_env(:geolocator, __MODULE__)[:locations_service_adapter]
  end
end
