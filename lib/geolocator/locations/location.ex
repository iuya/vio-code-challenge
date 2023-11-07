defmodule Geolocator.Locations.Location do
  @moduledoc """
  Defines the location schema and it's changeset.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false

  schema "locations" do
    field :ip_address, EctoNetwork.INET, primary_key: true
    field :country_code, :string
    field :country, :string
    field :city, :string
    field :latitude, :float
    field :longitude, :float
    field :mystery_value, :integer
  end

  @required_params [
    :ip_address,
    :country_code,
    :country,
    :city,
    :latitude,
    :longitude,
    :mystery_value
  ]
  @doc false
  def changeset(location, attrs) do
    location
    |> cast(attrs, @required_params)
    |> validate_required(@required_params)
  end
end
