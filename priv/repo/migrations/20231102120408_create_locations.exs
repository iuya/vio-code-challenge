defmodule Geolocator.Repo.Migrations.CreateLocations do
  use Ecto.Migration

  def change do
    create table(:locations, primary_key: false) do
      add :ip_address, :inet, primary_key: true
      add :country_code, :string, size: 2, null: false
      add :country, :string, null: false
      add :city, :string, null: false
      # It's not worth using more than 6 or 7 decimals https://gis.stackexchange.com/a/8674
      # 6 decimals have a precision of 110cm, for IP location that is more than enough
      # and we could probably reduce it to 4 decimals (11m resolution) w/o any issues while
      # saving quite a lot of disk on the long run.

      # It's not worth using numeric instead of float; float has a 11m precision
      # double has 0.00011mm precision which is overkill
      # Most libraries end up using floats/doubles or radians instead of DECIMAL
      # $  https://stackoverflow.com/a/53796521
      add :latitude, :float, null: false
      add :longitude, :float, null: false
      add :mystery_value, :bigint, null: false

      # This makes little sense if we are going to load the locations either only once or via scheduled job
      # in the future
      # timestamps(type: :utc_datetime)
    end
  end
end
