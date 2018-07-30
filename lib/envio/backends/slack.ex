defmodule Envio.Slack do
  @moduledoc false

  alias Envio.Utils

  @behaviour Envio.Backend

  @spec format(%{required(:atom) => term()}) :: binary()
  defp format(%{} = message) do
    with {title, message} <- Utils.get_delete(message, :title),
         {text, message} <- Utils.get_delete(message, :text),
         {body, message} <- Utils.get_delete(message, :message),
         {level, message} <- Utils.get_delete(message, :level, :info),
         {icon, message} <- Utils.get_delete(message, :icon, slack_icon(level)) do
      fields =
        message
        |> Iteraptor.to_flatmap()
        |> Enum.map(fn {k, v} ->
          v = Utils.smart_to_binary(v)
          %{
            title: k,
            value: v,
            short: String.length(v) < 32
          }
        end)

      pretext = [text, body] |> Enum.reject(&is_nil/1) |> Enum.join("\n")

      attachments =
        %{
          color: slack_color(level),
          fields: fields,
          mrkdwn_in: ["title", "text", "pretext"]
        }
        |> Map.merge(if text || body, do: %{pretext: "```\n" <> pretext <> "\n```"}, else: %{})

      fallback =
        [title, text, body]
        |> Enum.reject(&is_nil/1)
        |> Enum.map(&Utils.smart_to_binary/1)
        |> Enum.join("\n")

      %{
        emoji_icon: icon,
        fallback: fallback,
        mrkdwn: true,
        attachments: [attachments]
      }
      |> Map.merge(if text, do: %{text: text}, else: %{})
      |> Jason.encode!()
    end
  end


  @impl true
  def on_envio(message) do
    case Utils.get_delete(message, :meta) do
      {%{hook_url: hook_url}, message} ->
        HTTPoison.post(
          hook_url,
          format(message),
          [{"Content-Type", "application/json"}]
        )
      _ -> {:error, :no_hook_url_in_envio}
    end
  end

  #############################################################################

  defp slack_icon(:debug), do: ":speaker:"
  defp slack_icon(:info), do: ":information_source:"
  defp slack_icon(:warn), do: ":warning:"
  defp slack_icon(:error), do: ":exclamation:"
  defp slack_icon(level) when is_binary(level),
    do: level |> String.to_existing_atom() |> slack_icon()
  defp slack_icon(_), do: slack_icon(:info)

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
