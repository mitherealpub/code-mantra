defmodule CodeMantra.EvaluationDaemon do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, %{}, opts)
  def init(state), do: {:ok, state}

  def handle_cast({:evaluate_metrics, user_id, metrics}, state) do
    prefix = determine_prefix(metrics.commits_per_day, metrics.avg_lines_per_commit)
    syntax = determine_syntax(metrics.dominant_paradigm)
    legacy = determine_legacy(metrics.legacy_code_ratio)
    
    new_title = "The #{prefix} #{syntax} #{legacy}"
    
    # Broadcast down the WebSocket to display inline terminal coruscations
    # CodeMantraWeb.Endpoint.broadcast!("developer_workspace:#{user_id}", "royal_decree", %{title: new_title})
    {:noreply, state}
  end

  defp determine_prefix(cpd, alc) when cpd >= 8 and alc <= 50, do: "Flashing"
  defp determine_prefix(_, alc) when alc >= 500, do: "Monolithic"
  defp determine_prefix(_, _), do: "Steady"

  defp determine_syntax("functional"), do: "Lambda"
  defp determine_syntax("oop"), do: "Instance"
  defp determine_syntax("low_level"), do: "Pointer"
  defp determine_syntax("web_rogue"), do: "Callback"
  defp determine_syntax("web_illusionist"), do: "Cascade"

  defp determine_legacy(ratio) when ratio >= 0.6, do: "of the Sunken Technical Debt"
  defp determine_legacy(_), do: "of the Unblemished Canvas"
end
