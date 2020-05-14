defmodule Accent.Hook.Outbounds.Email do
  use Oban.Worker, queue: :hook

  alias Accent.{
    CreateCommentEmail,
    ProjectInviteEmail,
    Repo,
    Translation
  }

  @impl Oban.Worker
  def perform(context, _job) do
    context = Accent.Hook.Context.from_worker(context)

    context
    |> fetch_emails()
    |> build_email(context)
    |> Accent.Mailer.deliver_later()
  end

  defp build_email(emails, %{event: "create_collaborator", project: project, user: user}) do
    ProjectInviteEmail.create(emails, user, project)
  end

  defp build_email(emails, %{event: "create_comment", project: project, payload: payload}) do
    CreateCommentEmail.create(emails, project, payload)
  end

  defp fetch_emails(%{event: "create_collaborator", payload: payload}) do
    [get_in(payload, ~w(collaborator email))]
  end

  defp fetch_emails(%{event: "create_comment", payload: payload, user: context_user}) do
    translation_id = get_in(payload, ~w(translation id))

    Translation
    |> Repo.get(translation_id)
    |> Repo.preload(comments_subscriptions: :user)
    |> Map.get(:comments_subscriptions)
    |> Enum.filter(&(&1.user.id !== context_user.id))
    |> Enum.map(& &1.user.email)
  end
end
