import Config

# Configure de location controller
config :geolocator, GeolocatorWeb.LocationController,
  locations_service_adapter: Geolocator.Locations

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
