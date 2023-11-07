defmodule GeolocatorWeb.Router do
  use GeolocatorWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", GeolocatorWeb do
    pipe_through :api
    get "/locations/:ip_address", LocationController, :show
  end
end
