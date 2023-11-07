defmodule Mix.Tasks.Geolocator.Loader do
  @moduledoc """
  A mix task that starts the CSV load given a file path. Still requires a valid mix config;
  that is, a valid dev.exs for dev and valid env_vars for prod.
  """
  use Mix.Task

  alias Geolocator.Loader

  @shortdoc "Loads a CSV into the locations table."

  def run(args) do
    {valid_args, _, _} =
      OptionParser.parse(args, strict: [file: :string], aliases: [f: :file])

    with {:ok, file} <- Keyword.fetch(valid_args, :file),
         :ok <- Mix.Task.run("app.start"),
         {:ok, statistics} <- Loader.load_from_csv(file) do
      IO.puts(:stdio, inspect(statistics))
    else
      :error ->
        IO.puts(:stderr, "Missing required '--file' argument. Nothing to load.")
        exit({:shutdown, 1})

      {:error, :no_such_path} ->
        IO.puts(:stdio, "Invalid file path. Use -f <FILE_PATH>")
        exit({:shutdown, 2})
    end
  end
end
