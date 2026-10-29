defmodule CodeMantra.StreamAnimator do
  use GenServer
  require Logger

  # --- Client API ---

  @doc """
  Starts the standalone StreamAnimator process.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{frame: 0}, opts)
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(state) do
    Logger.info("[ACTOR 6: STREAM_ANIMATOR] Hybrid ASCII Text-Tile view rendering pipeline initialized.")
    {:ok, state}
  end

  @impl true
  def handle_cast({:queue_snapshot, user_id, player_stats, metrics}, state) do
    # 1. Map file paths to World Tree geography altitude tiers
    file_path = get_in(metrics.raw_telemetry, ["buffer_context", "file_path"]) || "root"
    tree_y = calculate_tree_altitude(file_path)
    
    # 2. Derive horizontal velocity from typing cadence (WPM)
    wpm = get_in(metrics.raw_telemetry, ["buffer_context", "wpm_cadence"]) || 0.0
    action_state = determine_sprite_action(wpm, metrics.raw_telemetry)

    # 3. Assemble single-player visual grid packet
    render_frame = %{
      frame_id: state.frame + 1,
      type: "SINGLE_PLAYER_GRID",
      player: %{
        name: player_stats.title || "The Unnamed Developer",
        level: player_stats.level || 1,
        gold: player_stats.gold || 0,
        sprite_x: rem(round(wpm * 4.5), 100), # Loops horizontal layout lanes safely
        sprite_y: tree_y,
        action: action_state
      },
      environment: %{
        zone: determine_zone_tier(tree_y),
        is_broken: !get_in(metrics.raw_telemetry, ["buffer_context", "is_compilable"])
      }
    }

    # 4. Stream real-time canvas updates down to public channel visualizers
    # CodeMantraWeb.Endpoint.broadcast!("stream_view:#{user_id}", "canvas_update", render_frame)

    {:noreply, %{state | frame: state.frame + 1}}
  end

  @impl true
  def handle_cast({:broadcast_multiplayer_battle, project_hash, monster_payload}, state) do
    # Assemble co-op turn-based display grid metrics 
    battle_frame = %{
      frame_id: state.frame + 1,
      type: "MULTIPLAYER_BATTLE_GRID",
      arena: %{
        project_hash: project_hash,
        monster_id: monster_payload.monster_id,
        monster_name: monster_payload.name,
        monster_hp: monster_payload.hp,
        monster_max_hp: monster_payload.max_hp,
        target_developer_id: monster_payload.aggro_target_id,
        ailment: monster_payload.status_ailment
      }
    }

    # Stream out to the shared team public visualization canvas overlay
    # CodeMantraWeb.Endpoint.broadcast!("stream_view:shared:#{project_hash}", "battle_update", battle_frame)

    {:noreply, %{state | frame: state.frame + 1}}
  end

  # --- Internal Spatial Mapping Utilities ---

  defp calculate_tree_altitude(path) do
    # Count nesting directories deep to resolve vertical displacement blocks
    slashes = String.graphemes(path) |> Enum.count(&(&1 == "/"))
    min(slashes * 12, 100) # Caps at maximum Yggdrasil canopy thresholds
  end

  defp determine_sprite_action(wpm, telemetry) do
    cond do
      get_in(telemetry, ["buffer_context", "is_compilable"]) == false -> "DEFENDING_COMPILER_ATTACK"
      wpm > 50.0 -> "BLAZING_FLOW_RUN"
      wpm > 15.0 -> "STEADY_GRIND_MARCH"
      true -> "IDLE_AWAITING_INPUT"
    end
  end

  defp determine_zone_tier(y) when y >= 75, do: "SKY_FORTRESS"
  defp determine_zone_tier(y) when y >= 50, do: "CANOPY_BRANCHES"
  defp determine_zone_tier(y) when y >= 25, do: "CORE_TRUNK"
  defp determine_zone_tier(y), do: "THE_ROOT_SYSTEM"
end
