defmodule Geolocator.Loader do
  @moduledoc """
  This module handles importing a csv into the database as well as introduce a Mix task to manually trigger
  the upload.
  """
  alias Ecto.Changeset
  alias Geolocator.Loader.Stats
  alias Geolocator.Locations.Location
  alias Geolocator.Repo

  @doc """
  Reads the csv located in the given path and loads it into the database. Then
  returns the stats associated with the upload
  """
  @spec load_from_csv(String.t()) :: {:ok, Stats.t()} | {:error, :no_such_path}
  def load_from_csv(file_path) do
    if File.exists?(file_path) do
      stream =
        file_path
        |> Path.expand()
        |> File.stream!([read_ahead: 100_000], 1000)

      batch_size = batch_size()
      IO.puts("Attempting csv load with batch size #{batch_size}")
      {elapsed_time_ms, {accepted, discarded}} = :timer.tc(&load_stream/2, [stream, batch_size])
      {:ok, Stats.new(accepted, discarded, elapsed_time_ms)}
    else
      {:error, :no_such_path}
    end
  end

  @spec load_stream(File.Stream.t(), integer()) :: {accepted :: integer, discarded :: integer}
  def load_stream(stream, batch_size) do
    stream
    |> CSV.decode(headers: true, field_transform: &String.trim/1)
    |> Stream.chunk_every(batch_size)
    |> Stream.map(fn chunk_of_rows ->
      {locations, stats} = Enum.reduce(chunk_of_rows, {%{}, {0, 0}}, &load_row/2)

      Repo.insert_all(
        Location,
        Map.values(locations),
        on_conflict: :replace_all,
        conflict_target: :ip_address
      )

      stats
    end)
    |> Enum.reduce(fn {accepted, discarded}, {total_accepted, total_discarded} ->
      {total_accepted + accepted, total_discarded + discarded}
    end)
  end

  defp load_row({:error, _invalid_row}, {location_map, {accepted, discarded}}) do
    {location_map, {accepted, discarded + 1}}
  end

  defp load_row({:ok, row_map}, {location_map, {accepted, discarded}}) do
    case Location.changeset(%Location{}, row_map) do
      %Changeset{valid?: true, changes: %{ip_address: ip_address} = new_location} ->
        # We want to overwrite any previous row with the same ip that may appear in this chunk
        # since Postgress cannot resolve the conflict when the row appears multiple times in the same
        # operation:
        # ** (Postgrex.Error) ERROR 21000 (cardinality_violation) ON CONFLICT DO UPDATE command cannot affect row a second time
        new_location_map = Map.put(location_map, ip_address, new_location)
        {new_location_map, {accepted + 1, discarded}}

      %Changeset{valid?: false, errors: _errors} ->
        {location_map, {accepted, discarded + 1}}
    end
  end

  def batch_size() do
    # Max batch size that Postgres is going to accept w/o breaking is 9362 rows (65535 parameters / 7 parameters per row)
    Application.get_env(:geolocator, __MODULE__)[:batch_size] || 2000
  end
end
