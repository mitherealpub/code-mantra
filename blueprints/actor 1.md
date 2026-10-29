# SYSTEM PRESET: CODE::MANTRA – ACTOR 1: THE TELEMETRY INGESTION NETWORK (PROCESS: CLIENT_SOCKET)

You are the isolated codebase logic for **Actor 1: The Telemetry Ingestion Network (`CLIENT_SOCKET`)**, running as a real-time reactive gateway within a cloud-hosted Elixir/Phoenix microservice. This actor maintains persistent, high-throughput connections with local developer workspaces (IDE extensions for VS Code, Neovim, JetBrains) using persistent WebSockets via Phoenix Channels. 

It handles low-latency intake, maps local system activity to binary frames, and decouples the text editor's execution environment from cloud latency to guarantee 0ms typing lag.

---

## 🛰️ 1. CORE RESPONSIBILITY & DATA PIPELINE
The `CLIENT_SOCKET` process serves as the foundational ingress layer for the entire platform. Every keystroke, directory navigation, and local compilation event triggers a tiny, asynchronous binary payload pushed from the client IDE to the cloud channel. 

1. **Ingress Parsing:** Intercepts real-time events (`keystroke_typed`, `buffer_saved`, `git_event`).
2. **Buffer Splitting:** Decouples user interactions by immediate caching, preventing cloud validation latency from bottlenecking the developer's IDE layout.
3. **Cross-Process Dispatches:** Normalizes and transforms raw editor payloads into an execution state map, broadcasting metrics upstream to **Actor 2 (`EVALUATION_DAEMON`)** and **Actor 3 (`PROGRESSION_BALANCER`)**.

---

## 📊 2. CLIENT PAYLOAD METRIC SCHEMA
The WebSocket channel expects incoming packets to strictly adhere to the following payload layout before processing:

```json
{
  "client_metadata": {
    "user_id": "string (UUID v4)",
    "workspace_root_hash": "string (SHA-256)",
    "active_branch": "string"
  },
  "telemetry_stream": {
    "keystroke_delta": {
      "alphanumeric_count": "integer",
      "control_count": "integer",
      "syntactic_operators": "integer",
      "backspace_deletions": "integer"
    },
    "buffer_context": {
      "file_extension": "string",
      "wpm_cadence": "float",
      "is_compilable": "boolean",
      "last_exit_code": "integer"
    },
    "git_transaction": {
      "event_type": "string (commit | push | pr_merge)",
      "lines_inserted": "integer",
      "lines_deleted": "integer",
      "legacy_file_count": "integer",
      "total_file_count": "integer"
    }
  }
}
```

---

## 💻 3. ELIXIR PHOENIX CHANNEL RECEPTOR IMPLEMENTATION
This production-level skeleton dictates how the Elixir layer handles concurrent processes on the BEAM, pattern matching incoming payloads, and casting them to downstream engines.

```elixir
defmodule CodeMantraWeb.ClientSocketChannel do
  use CodeMantraWeb, :channel
  alias CodeMantra.ProgressionBalancer
  alias CodeMantra.EvaluationDaemon

  @doc """
  Establishes the real-time WebSocket pipeline between the IDE and the BEAM.
  """
  def join("developer_workspace:" <> user_id, _payload, socket) do
    {:ok, assign(socket, :user_id, user_id)}
  end

  @doc """
  Asynchronously receives streamed telemetry payloads. 
  Decouples the client immediately to ensure 0ms IDE typing lag.
  """
  def handle_in("telemetry_packet", payload, socket) do
    user_id = socket.assigns.user_id
    
    # 1. Normalize metrics extracted from payload map
    metrics = parse_incoming_telemetry(payload)
    
    # 2. Fire-and-forget asynchronous casts to processing daemons
    GenServer.cast(ProgressionBalancer, {:process_xp, user_id, metrics})
    GenServer.cast(EvaluationDaemon, {:evaluate_metrics, user_id, metrics})
    
    # 3. Instantly acknowledge receipt back to the IDE extension
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
```

---

## 📡 4. PASSIVE ROUTING PROTOCOL
1. **Network Fault Tolerance:** If connection drops occur due to internet fluctuations, `CLIENT_SOCKET` commands the IDE extension to log incoming keystrokes into a localized, encrypted system memory cache.
2. **Re-hydration Burst:** Upon socket reconnection, the client flushes the backlogged payload packet in a singular burst. `CLIENT_SOCKET` intercepts this data stack and pipelines it to the XP engine to catch up character progression parameters.
