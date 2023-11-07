defmodule GeolocatorWeb.ErrorJSONTest do
  use GeolocatorWeb.ConnCase, async: true

  test "renders 404" do
    assert GeolocatorWeb.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 400" do
    assert GeolocatorWeb.ErrorJSON.render("400.json", %{}) == %{errors: %{detail: "Bad Request"}}
  end

  test "renders 500" do
    assert GeolocatorWeb.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
