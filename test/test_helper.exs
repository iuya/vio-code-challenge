Mox.defmock(Geolocator.LocationsMock, for: Geolocator.Locations)

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Geolocator.Repo, :manual)
