defmodule App.Application do
  @moduledoc """
  The App Application Service.

  The app system business domain lives in this application.

  Exposes API to clients such as the `AppWeb` application
  for use in channels, controllers, and elsewhere.
  """
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    Supervisor.start_link([
      supervisor(App.Repo, []),
    ], strategy: :one_for_one, name: App.Supervisor)
  end
end
