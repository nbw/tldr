ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Tldr.Repo, :manual)

# Define Mox mocks
Mox.defmock(Tldr.Core.HttpClientMock, for: Tldr.Core.HttpClient.Behaviour)
