defmodule Nomnomnom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      NomnomnomWeb.Telemetry,
      Nomnomnom.Repo,
      {DNSCluster, query: Application.get_env(:nomnomnom, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Nomnomnom.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Nomnomnom.Finch},
      # Start a worker by calling: Nomnomnom.Worker.start_link(arg)
      # {Nomnomnom.Worker, arg},
      # Start to serve requests, typically the last entry
      NomnomnomWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Nomnomnom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    NomnomnomWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
