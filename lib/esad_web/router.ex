defmodule EsadWeb.Router do
  use EsadWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EsadWeb do
    pipe_through :browser

    get "/", PageController, :index
    get "/streams", StreamController, :list
    get "/streams/:stream", StreamController, :stream
  end

  # Other scopes may use custom stacks.
  # scope "/api", EsadWeb do
  #   pipe_through :api
  # end
end
