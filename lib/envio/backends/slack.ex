defmodule Envio.Slack do
  @moduledoc false

  alias Envio.Utils

  @spec format(channel :: binary(), username :: binary(), %{required(:atom) => term()}) :: binary()
  defp format(channel, username, %{} = message) when is_binary(channel) and is_binary(username) do
    with {text, message} <- Utils.get_delete(message, :text),
         {pretext, message} <- Utils.get_delete(message, :pretext),
         {level, message} <- Utils.get_delete(message, :level, :info),
         {icon, message} <- Utils.get_delete(message, :icon, slack_icon(level)) do
      fields =
        Enum.map(message, fn {k, v} ->
          %{
            title: k,
            value: Utils.smart_to_binary(v),
            short: String.length(v) < 32
          }
        end)

      attachments =
        %{
          color: slack_color(level),
          fields: fields,
          mrkdwn_in: ["title", "text", "pretext"]
        }
        |> Map.merge(if pretext, do: %{pretext: "```\n#{pretext}\n```"}, else: %{})

      fallback =
        [text, pretext, message]
        |> Enum.map(&Utils.smart_to_binary/1)
        |> Enum.join("\n")

      %{
        channel: channel,
        username: username,
        emoji_icon: icon,
        fallback: fallback,
        mrkdwn: true,
        attachments: [attachments]
      }
      |> Map.merge(if text, do: %{text: text}, else: %{})
      |> Jason.encode!()
    end
  end

  @spec slack!(
          hook_url :: binary(),
          channel :: binary(),
          username :: binary(),
          message :: %{required(:atom) => term()}
        ) :: {:ok, %HTTPoison.Response{}}
  def slack!(hook_url, channel, username, message) do
    HTTPoison.post(
      hook_url,
      format(channel, username, message),
      [{"Content-Type", "application/json"}]
    )
  end

  #############################################################################

  defp slack_icon(:debug), do: ":speaker:"
  defp slack_icon(:info), do: ":information_source:"
  defp slack_icon(:warn), do: ":warning:"
  defp slack_icon(:error), do: ":exclamation:"

  defp slack_color(:debug), do: "#AAAAAA"
  defp slack_color(:info), do: "good"
  defp slack_color(:warn), do: "#FF9900"
  defp slack_color(:error), do: "danger"

  #############################################################################

  defp meet_level?(lvl, min), do: compare_levels(lvl, min) != :lt

  defp compare_levels(level, level), do: :eq
  defp compare_levels(_level, nil), do: :gt

  defp compare_levels(left, right),
    do: if(level_to_number(left) > level_to_number(right), do: :gt, else: :lt)

  defp level_to_number(:debug), do: 0
  defp level_to_number(:info), do: 1
  defp level_to_number(:warn), do: 2
  defp level_to_number(:error), do: 3
end
