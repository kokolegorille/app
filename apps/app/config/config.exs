use Mix.Config

config :app, ecto_repos: [App.Repo]

import_config "#{Mix.env}.exs"
