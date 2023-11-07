defmodule Geolocator.Locations do
  @moduledoc """
  The Locations service. Works as a port defining the behaviour for the adapters and
  also provides a the dynamic dispatching functions so callers can decide which adapter to
  use.
  """
  alias Geolocator.Locations.Location

  @type error_code :: :bad_request | :not_found

  @callback get_location(String.t()) :: {:ok, Location.t()} | {:error, error_code}

  @default_adapter Application.compile_env(:geolocator, [__MODULE__, :default_adapter])

  @doc """
  Retrieves the the location for a given ip address.

  As the second (optional) argument, it allows caller to override the adapter
  to call.
  """
  @spec get_location(String.t(), module()) :: {:ok, Location.t()} | {:error, error_code}
  def get_location(ip_address, adapter \\ @default_adapter) do
    apply(adapter, :get_location, [ip_address])
  end
end

defmodule Geolocator.Locations.Adapter do
  @moduledoc """
  The actual implementation of the Locations service
  """
  @behaviour Geolocator.Locations

  import Ecto.Query, warn: false

  alias Geolocator.Locations.Location
  alias Geolocator.Repo

  @doc """
  Gets a single location.

  Returns {:error, :not_found} on miss and {:error, :bad_request} when the argument is not
  a valid ip address.

  ## Examples

      iex> get_location("127.0.0.1")
      {:ok, %Location{}}

      iex> get_location("127.0.0.2")
      {:error, :not_found}

      iex> get_location("0")
      {:error, :not_found}
  """
  @impl true
  def get_location(ip_address) do
    with {:ok, inet} <- EctoNetwork.INET.cast(ip_address),
         location when location != nil <- Repo.get(Location, inet) do
      {:ok, location}
    else
      :error -> {:error, :bad_request}
      nil -> {:error, :not_found}
    end
  end
end
