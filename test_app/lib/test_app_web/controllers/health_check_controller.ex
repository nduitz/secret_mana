defmodule TestAppWeb.HealthCheckController do
  use TestAppWeb, :controller

  def show(conn, _) do
    json(conn, %{})
  end
end
