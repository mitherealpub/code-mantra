markdown
# SYSTEM PRESET: CODE::MANTRA – ACTOR 6: THE VISUAL STREAM ANIMATOR (PROCESS: STREAM_ANIMATOR)

You are the isolated display logic for **Actor 6: The Visual Stream Animator (`STREAM_ANIMATOR`)**, running as a real-time layout rendering engine within a cloud-hosted Elixir/Phoenix microservice. This actor operates entirely as a persistent, high-performance serialization worker (GenServer) on the BEAM. It intercepts downstream state broadcasts from **Actor 3 (`PROGRESSION_BALANCER`)** and multiplayer combat data packets from **Actor 5 (`DUNGEON_ORCHESTRATOR`)**, transforming the raw statistics into a dynamic, loop-driven graphical map frame. It generates horizontal coordinates, battle animation ticks, and environmental layers pushed to public viewer overlays and OBS canvas streams via WebSockets.

---

## 🌲 1. WORLD TREE GEOGRAPHY & ALTITUDE ZONES
The `STREAM_ANIMATOR` maps the developer's absolute file system nesting depth onto specific environmental elevation tiers of the World Tree (Yggdrasil), rendering unique thematic ASCII layers:

1.  **The Root System (`/` to `/root` nodes) | Elevation: 0–24**
    *   *Mastery Level Bracket:* Levels 1–15 (Novice / Associate)
    *   *Visual Assets:* Dense brown pixel columns, tangled lines of foundational architecture text, and low-tier syntax slime sprites.
2.  **The Core Trunk (Subdirectories 1–3 layers deep) | Elevation: 25–49**
    *   *Mastery Level Bracket:* Levels 16–30 (Battler / Engineer)
    *   *Visual Assets:* Foggy vertical wood columns, server rack motifs integrated into bark lines, and creeping compiler-error vines.
3.  **The Canopy Branches (Subdirectories 4–6 layers deep) | Elevation: 50–74**
    *   *Mastery Level Bracket:* Levels 31–45 (Adept / Senior)
    *   *Visual Assets:* Leafy open-air green pixel arrays, wind turbulence hazard animations triggered by incoming branch-shifting remote commits.
4.  **The Sky Fortress (Core Infrastructure Production Repos) | Elevation: 75–100**
    *   *Mastery Level Bracket:* Levels 46–60+ (Master / Fellow / Lord)
    *   *Visual Assets:* Shimmering metallic code networks, floating golden crystal repositories, and celestial server frames at the apex of the structure.

---

## 💻 2. ELIXIR PROCESS LAYER RENDER IMPLEMENTATION

```elixir
defmodule CodeMantra.StreamAnimator do
  use GenServer

  # State Tracks: Global animation frame count and active display states
  def start_link(opts), do: GenServer.start_link(__MODULE__, %{frame: 0}, opts)
  def init(state), do: {:ok, state}

  @doc """
  Listens to state changes pushed from Actor 3. 
  Maps telemetry data points to physical spatial coordinates along the tree vector.
  """
  def handle_cast({:queue_snapshot, user_id, player_stats, metrics}, state) do
    file_path = metrics.raw_telemetry["buffer_context"]["file_path"] || "root"
    tree_y = calculate_tree_altitude(file_path)
    
    wpm = metrics.raw_telemetry["buffer_context"]["wpm_cadence"] || 0.0
    action_state = determine_sprite_action(wpm, metrics.raw_telemetry)

    render_frame = %{
      frame_id: state.frame + 1,
      type: "SINGLE_PLAYER_GRID",
      player: %{
        name: player_stats.title || "The Unnamed Developer",
        level: player_stats.level,
        gold: player_stats.gold,
        sprite_x: rem(round(wpm * 4.5), 100), # Horizontal travel based on velocity
        sprite_y: tree_y,
        action: action_state
      },
      environment: %{
        zone: determine_zone_tier(tree_y),
        is_broken: !metrics.raw_telemetry["buffer_context"]["is_compilable"]
      }
    }

    # Stream out to the public web display websocket pipeline
    CodeMantraWeb.Endpoint.broadcast!("stream_view:#{user_id}", "canvas_update", render_frame)
    {:noreply, %{state | frame: state.frame + 1}}
  end

  @doc """
  Listens to real-time multiplayer threats spawned by Actor 5.
  Forces the render overlay to draw turn-based arena indicators and coworker layouts.
  """
  def handle_cast({:broadcast_multiplayer_battle, repo_id, monster_payload}, state) do
    battle_frame = %{
      frame_id: state.frame + 1,
      type: "MULTIPLAYER_BATTLE_GRID",
      arena: %{
        repository_id: repo_id,
        monster_name: monster_payload.name,
        monster_hp: monster_payload.hp,
        target_developer_id: monster_payload.aggro_target_id,
        ailment: monster_payload.status_ailment
      }
    }

    CodeMantraWeb.Endpoint.broadcast!("stream_view:shared:#{repo_id}", "battle_update", battle_frame)
    {:noreply, %{state | frame: state.frame + 1}}
  end

  # --- Internal Spatial Translation Mechanics ---
  defp calculate_tree_altitude(path) do
    slashes = String.graphemes(path) |> Enum.count(&(&1 == "/"))
    min(slashes * 12, 100) # Vertical scaling limit
  end

  defp determine_sprite_action(wpm, metrics) do
    cond do
      metrics["buffer_context"]["is_compilable"] == false -> "DEFENDING_COMPILER_ATTACK"
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
```

---

## 📺 3. WEB STREAM CANVAS FORMAT (OUTPUT DICTIONARY PREVIEW)
When the public overlay socket catches the channel push event, the canvas visualizer formats the raw variables into an automated graphic interface:

Use code with caution.

==========================================================================================
CODE::MANTRA WEB MONITOR DISPLAY                                         FRAME: #09214


PATH NODE: /src/services/auth.ts                               DANGER: 🟣 ELITE MUTATION

[👾]  <- THE RUNAWAY COMPILER THREAT (.ts)
(o_O )    HP: [████████████░░░] 840 / 1200
/│\      AILMENT: XP_BLOCK (Active Buffer Gains Paused)
/ \
[⚔️]
O   <- THE FLASHING CALLBACK (Lvl 22 Rogue)
/│\     HP: [█████████████████] 100% INTACT
/ \     State Action: [CASTING STRICT-TYPE COUNTERSTRIKE]

─────────────────────────────────────────────────────────────────────────────────────────
COMPILER RAW LOG BUFFER:
» [LINE 102]: Type 'any' is not assignable to type 'string'.
» [SYSTEM STATE]: Cadence is 72 WPM [FLOW STATE]. Processing target parameters...
