defmodule Nomnomnom.Repo do
  use Ecto.Repo,
    otp_app: :nomnomnom,
    adapter: Ecto.Adapters.Postgres
end
