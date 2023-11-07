import Config

# Configure de location controller
config :geolocator, GeolocatorWeb.LocationController,
  locations_service_adapter: Geolocator.LocationsMock

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :geolocator, Geolocator.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "geolocator_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :geolocator, GeolocatorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "+N9ilHn+sr84cTS9v8cQ9tLjE0OmddI8T6tgHW8wo19ksOLDOD/vTBdokhnZ0hGF",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
