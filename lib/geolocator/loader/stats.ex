defmodule Geolocator.Loader.Stats do
  @moduledoc """
  A struct used to store and return the stats from loading a CSV.
  """

  @type t :: %__MODULE__{
          total: integer,
          accepted: integer,
          discarded: integer,
          elapsed_time_ms: integer
        }

  defstruct total: 0,
            accepted: 0,
            discarded: 0,
            elapsed_time_ms: 0

  @spec new(integer(), integer(), integer()) :: __MODULE__.t()
  def new(accepted, discarded, elapsed_time_ms) do
    %__MODULE__{
      total: accepted + discarded,
      accepted: accepted,
      discarded: discarded,
      elapsed_time_ms: elapsed_time_ms
    }
  end
end
