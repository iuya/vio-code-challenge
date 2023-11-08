defmodule Geolocator.LoaderTest do
  @moduledoc """
  Tests the Geolocator.Loader module
  """

  use Geolocator.DataCase

  alias Geolocator.Locations.Location
  alias Geolocator.Loader
  alias Geolocator.Repo

  @batch_size 10

  describe "loader" do
    test "success with 3 valid rows" do
      valid_csv = """
      ip_address,country_code,country,city,latitude,longitude,mystery_value
      200.106.141.15,SI,Nepal,DuBuquemouth,-84.87503094689836,7.206435933364332,7823011346
      160.103.7.140,CZ,Nicaragua,New Neva,-68.31023296602508,-37.62435199624531,7301823115
      70.95.73.73,TL,Saudi Arabia,Gradymouth,-49.16675918861615,-86.05920084416894,2559997162
      """

      {:ok, stream} = StringIO.open(valid_csv)

      assert {3, 0} =
               stream
               |> IO.binstream(:line)
               |> Loader.load_stream(@batch_size)
    end

    test "duplicates which count as accepted (conflicts replace previous version)" do
      # The last row causes a conflict with the first one
      conflicting_csv = """
      ip_address,country_code,country,city,latitude,longitude,mystery_value
      200.106.141.15,SI,Nepal,DuBuquemouth,-84.87503094689836,7.206435933364332,7823011346
      160.103.7.140,CZ,Nicaragua,New Neva,-68.31023296602508,-37.62435199624531,7301823115
      70.95.73.73,TL,Saudi Arabia,Gradymouth,-49.16675918861615,-86.05920084416894,2559997162
      200.106.141.15,ES,Spain,Madrid,40.4168,-3.703790,0
      """

      {:ok, stream} = StringIO.open(conflicting_csv)

      assert {4, 0} =
               stream
               |> IO.binstream(:line)
               |> Loader.load_stream(@batch_size)

      assert %Location{
               ip_address: %Postgrex.INET{address: {200, 106, 141, 15}, netmask: 32},
               country_code: "ES",
               country: "Spain"
             } =
               Repo.get(Location, "200.106.141.15")
    end

    test "lines with empty fields are ignored" do
      csv_with_empty_fields = """
      ip_address,country_code,country,city,latitude,longitude,mystery_value
      200.106.141.15,SI,Nepal,DuBuquemouth,-84.87503094689836,7.206435933364332,7823011346
      160.103.7.140,CZ,Nicaragua,New Neva,-68.31023296602508,-37.62435199624531,7301823115
      70.95.73.73,TL,,,-49.16675918861615,-86.05920084416894,2559997162
      """

      {:ok, stream} = StringIO.open(csv_with_empty_fields)

      assert {2, 1} =
               stream
               |> IO.binstream(:line)
               |> Loader.load_stream(@batch_size)
    end

    test "csv with invalid headers will discard everything (valid headers are needed for loading)" do
      invalid_header_csv = """
      ip_address,,country,city,latitude,longitude,mystery_value
      200.106.141.15,SI,Nepal,DuBuquemouth,-84.87503094689836,7.206435933364332,7823011346
      160.103.7.140,CZ,Nicaragua,New Neva,-68.31023296602508,-37.62435199624531,7301823115
      70.95.73.73,TL,Saudi Arabia,Gradymouth,-49.16675918861615,-86.05920084416894,2559997162
      """

      {:ok, stream} = StringIO.open(invalid_header_csv)

      assert {0, 3} =
               stream
               |> IO.binstream(:line)
               |> Loader.load_stream(@batch_size)
    end

    test "csv with missing headers will also discard everything (will take first row as headers)" do
      missing_headers_csv = """
      200.106.141.15,SI,Nepal,DuBuquemouth,-84.87503094689836,7.206435933364332,7823011346
      160.103.7.140,CZ,Nicaragua,New Neva,-68.31023296602508,-37.62435199624531,7301823115
      70.95.73.73,TL,Saudi Arabia,Gradymouth,-49.16675918861615,-86.05920084416894,2559997162
      """

      {:ok, stream} = StringIO.open(missing_headers_csv)

      assert {0, 2} =
               stream
               |> IO.binstream(:line)
               |> Loader.load_stream(@batch_size)
    end

    test "rows with type mismatches will be rejected" do
      # Here there are 2 rows with errors, the first one does not have a valid ip_address
      # and the second one has strings instead of floats for coordinates
      missing_headers_csv = """
      ip_address,country_code,country,city,latitude,longitude,mystery_value
      oops,SI,Nepal,DuBuquemouth,-84.87503094689836,7.206435933364332,7823011346
      160.103.7.140,CZ,Nicaragua,New Neva,missing_latitude,missing_longitude,7301823115
      70.95.73.73,TL,Saudi Arabia,Gradymouth,-49.16675918861615,-86.05920084416894,2559997162
      """

      {:ok, stream} = StringIO.open(missing_headers_csv)

      assert {1, 2} =
               stream
               |> IO.binstream(:line)
               |> Loader.load_stream(@batch_size)
    end
  end
end
