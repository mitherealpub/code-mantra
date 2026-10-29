defmodule CodeMantraWeb.ClientSocketChannel do
  use Phoenix.Channel
  alias CodeMantra.ProgressionBalancer
  alias CodeMantra.EvaluationDaemon
  alias CodeMantra.ProjectRegistry

  def join("developer_workspace:" <> user_id, %{"project_hash" => project_hash}, socket) do
    # Register with the obfuscation container to assess multiplayer alignment
    {:ok, team_status} = ProjectRegistry.register_developer(CodeMantra.ProjectRegistry, user_id, project_hash)
    
    socket = socket
    |> assign(:user_id, user_id)
    |> assign(:project_hash, project_hash)
    |> assign(:team_status, team_status)

    {:ok, team_status, socket}
  end

  def handle_in("telemetry_packet", payload, socket) do
    user_id = socket.assigns.user_id
    metrics = parse_incoming_telemetry(payload)
    
    GenServer.cast(CodeMantra.ProgressionBalancer, {:process_xp, user_id, metrics})
    GenServer.cast(CodeMantra.EvaluationDaemon, {:evaluate_metrics, user_id, metrics})
    
    {:reply, :ok, socket}
  end

  defp parse_incoming_telemetry(payload) do
    %{
      commits_per_day: get_in(payload, ["telemetry_stream", "git_transaction", "commits_per_day"]) || 0.0,
      avg_lines_per_commit: get_in(payload, ["telemetry_stream", "git_transaction", "lines_inserted"]) || 0,
      dominant_paradigm: classify_extension(get_in(payload, ["telemetry_stream", "buffer_context", "file_extension"])),
      legacy_code_ratio: calculate_legacy_ratio(payload),
      raw_telemetry: payload["telemetry_stream"]
    }
  end

  defp classify_extension(ext) when ext in [".hs", ".ex", ".clj", ".scala"], do: "functional"
  defp classify_extension(ext) when ext in [".java", ".cs", ".cpp", ".py"], do: "oop"
  defp classify_extension(ext) when ext in [".c", ".rs", ".asm", ".zig"], do: "low_level"
  defp classify_extension(ext) when ext in [".ts", ".js"], do: "web_rogue"
  defp classify_extension(ext) when ext in [".css", ".html", ".svelte"], do: "web_illusionist"
  defp classify_extension(_), do: "oop"

  defp calculate_legacy_ratio(payload) do
    legacy = get_in(payload, ["telemetry_stream", "git_transaction", "legacy_file_count"]) || 0
    total = get_in(payload, ["telemetry_stream", "git_transaction", "total_file_count"]) || 1
    legacy / max(total, 1)
  end
end
