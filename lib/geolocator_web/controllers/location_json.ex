defmodule GeolocatorWeb.LocationJSON do
  alias Geolocator.Locations.Location

  @doc """
  Renders a single location.
  """
  def show(%{location: %Location{} = location}) do
    %{
      ip_address: EctoNetwork.INET.decode(location.ip_address),
      country_code: location.country_code,
      country: location.country,
      city: location.city,
      latitude: location.latitude,
      longitude: location.longitude,
      mystery_value: location.mystery_value
    }
  end
end
