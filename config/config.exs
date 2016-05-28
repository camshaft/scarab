use Mix.Config

if Mix.env != :prod do
  config :ex_aws, :s3,
    scheme: "http://",
    host: %{
      "us-east-1" => "local.dev:8123"
    },
    region: "us-east-1"
end
