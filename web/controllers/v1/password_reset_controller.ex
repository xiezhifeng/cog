defmodule Cog.V1.PasswordResetController do
  use Cog.Web, :controller
  require Logger

  alias Cog.Repository.Users

  def create(conn, %{"email_address" => email_address}) do
    with {:ok, user} <- Users.by_email(email_address),
         {:ok, _} <- Users.request_password_reset(user) do
      send_resp(conn, :no_content, "")
    else
      {:error, :not_found} ->
        Logger.warn("Unknown email address sent for password reset")
        send_resp(conn, :no_content, "")
      {:error, error} ->
        Logger.warn("Failed to generate password reset: #{inspect error}")
        send_resp(conn, :internal_server_error, "")
    end
  end

  def update(conn, %{"id" => id, "password" => password}) do
    case Users.reset_password(id, password) do
      {:ok, user} ->
        render(conn, Cog.V1.UserView, "show.json", user: user)
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{errors: "Invalid password reset token."})
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Cog.ChangesetView, "error.json", changeset: changeset)
    end
  end

end
