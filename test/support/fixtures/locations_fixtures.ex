defmodule Geolocator.LocationsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Geolocator.Locations` context.
  """

  alias Geolocator.Repo
  alias Geolocator.Locations.Location

  @doc """
  Generate a location.
  """
  def location_fixture(attrs \\ %{}) do
    {:ok,
     location:
       %Location{}
       |> Location.changeset(attrs)
       |> Repo.insert!()}
  end
end
