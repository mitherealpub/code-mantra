defmodule CodeMantra.Application do
  @moduledoc """
  The core boot application for Code::Mantra.
  Establishes the distributed, fault-tolerant Supervision Tree across the BEAM.
  """
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    Logger.info("====== INITIALIZING CODE::MANTRA CLOUD LAYER CORE MIX ENGINE ======")

    # Define the precise startup hierarchy of all 8 independent background actors
    children = [
      # 1. Actor 7: The Data Privacy Anonymizer & Team Aggregating Hub
      {CodeMantra.ProjectRegistry, name: CodeMantra.ProjectRegistry},

      # 2. Actor 5: The Multiplayer Threat Coordinator & Procedural Bug Synthesizer
      {CodeMantra.DungeonOrchestrator, name: CodeMantra.DungeonOrchestrator},

      # 3. Actor 3: The Arithmetic Progression Manager & Leveling Curve Balancer
      {CodeMantra.ProgressionBalancer, name: CodeMantra.ProgressionBalancer},

      # 4. Actor 2: The Core Game Linter & Title Coronation Auditor
      {CodeMantra.EvaluationDaemon, name: CodeMantra.EvaluationDaemon},

      # 5. Actor 4: The Runic Base32 Encrypter & SHA-256 Checksum Validator
      {CodeMantra.PersistenceDaemon, name: CodeMantra.PersistenceDaemon},

      # 6. Actor 8: The Economy Ledger, Inventory Tracker & Status Ailment Clock
      {CodeMantra.EconomyLedger, name: CodeMantra.EconomyLedger},

      # 7. Actor 6: The Hybrid ASCII Tile Frame Assembler & OBS Canvas Overlay
      {CodeMantra.StreamAnimator, name: CodeMantra.StreamAnimator}

      # 8. Actor 1: Managed independently as part of the Phoenix Endpoint Socket Layer
      # CodeMantraWeb.Endpoint
    ]

    # Strategy: :one_for_one -> If one actor crashes, only that individual actor restarts.
    # The stats, sockets, and memory loops of the other 7 actors remain completely untouched.
    opts = [
      strategy: :one_for_one, 
      name: CodeMantra.Supervisor,
      max_restarts: 3,
      max_seconds: 5
    ]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("[SYSTEM KERNEL] All 8 core background actors deployed safely on the BEAM.")
        Logger.info("[SYSTEM KERNEL] Code::Mantra is ready for upstream WebSocket telemetry payloads.")
        {:ok, pid}

      {:error, reason} ->
        Logger.error("[SYSTEM KERNEL] Critical boot obstruction: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
