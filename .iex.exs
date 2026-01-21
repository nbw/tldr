alias Tldr.Adapters.HackerNews.Rss

alias Tldr.Kitchen

alias Tldr.Kitchen.{
  Actions,
  Chef,
  Recipe,
  Step
}

alias Tldr.Kitchen.Actions.{
  Formatter,
  Api,
  Limit
}

alias Tldr.Accounts.Scope
alias Tldr.Accounts
alias Tldr.AI
alias Tldr.AI.AgentServer
alias Tldr.AI.Chat

user = Accounts.get_user!(1)

scope = Scope.for_user(user)

recipe = Kitchen.get_recipe!(scope, 3)
