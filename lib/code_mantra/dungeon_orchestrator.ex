defmodule CodeMantra.DungeonOrchestrator do
  use GenServer
  require Logger
  alias CodeMantra.StreamAnimator

  # --- Client API ---

  @doc """
  Starts the standalone DungeonOrchestrator process.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{active_raids: %{}, monster_counters: %{}}, opts)
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(state) do
    Logger.info("[ACTOR 5: DUNGEON_ORCHESTRATOR] Initialized multiplayer instances and threat synthesis subroutines.")
    {:ok, state}
  end

  @impl true
  def handle_cast({:initialize_multiplayer_raid, project_hash, party_member_ids}, state) do
    Logger.info("[DUNGEON_ORCHESTRATOR] Co-op party matchmaking triggered for project hash [#{project_hash}]. Team size: #{length(party_member_ids)}")
    
    raid_payload = %{
      project_hash: project_hash,
      party_members: party_member_ids,
      active_monsters: %{},
      environmental_state: "PRISTINE"
    }

    new_raids = Map.put(state.active_raids, project_hash, raid_payload)
    
    # Broadcast to the shared repository channel that a team party has been instantiated
    # Phoenix.PubSub interface hook
    # CodeMantraWeb.Endpoint.broadcast!("repo_dungeon:#{project_hash}", "raid_formed", %{members: party_member_ids})

    {:noreply, %{state | active_raids: new_raids}}
  end

  @impl true
  def handle_cast({:analyze_shared_health, project_hash, pusher_id, telemetry}, state) do
    # 1. Parse raw structural telemetry markers down from Actor 1
    complexity = telemetry.cyclomatic_complexity || 1
    nesting_depth = telemetry.nesting_depth || 1
    is_broken = telemetry.is_compilable == false
    has_conflict = telemetry.has_merge_conflict == true
    file_path = telemetry.file_path || "unknown.ts"

    # 2. Check if the code safety boundaries are breached to compile a monster threat
    if is_broken or has_conflict or complexity >= 5 do
      prefix = determine_severity_prefix(complexity, telemetry.total_lines || 0)
      typology = determine_defect_typology(is_broken, has_conflict, telemetry.defect_type)
      element = Path.extname(file_path)

      # Generate unique tracking tags
      counter = Map.get(state.monster_counters, project_hash, 0) + 1
      monster_id = "MOB-#{project_hash}-#{counter}"
      monster_name = "The #{prefix} #{typology} (#{element})"

      monster_payload = %{
        monster_id: monster_id,
        name: monster_name,
        hp: complexity * 150,
        max_hp: complexity * 150,
        attack_power: floor(nesting_depth * 20),
        aggro_target_id: pusher_id,
        status_ailment: assign_status_ailment(typology)
      }

      # Update localized raid state
      state = update_raid_monsters(state, project_hash, monster_id, monster_payload)

      # 3. Propagate multiplayer hazard alerts down the Phoenix channel room grid
      # CodeMantraWeb.Endpoint.broadcast!("repo_dungeon:#{project_hash}", "monster_spawn", %{
      #   monster: monster_payload,
      #   environmental_hazard: if(is_broken, do: "GIT_FRACTURE_BURNING_LINES", else: "NONE"),
      #   alert_banner: "⚠️ REPOSITORY DUNGEON ALERT: #{monster_name} has mutated out of code changes!"
      # })

      # 4. Forward async rendering update coordinates to Actor 6 (Stream Animator)
      GenServer.cast(CodeMantra.StreamAnimator, {:broadcast_multiplayer_battle, project_hash, monster_payload})

      {:noreply, %{state | monster_counters: Map.put(state.monster_counters, project_hash, counter)}}
    else
      {:noreply, state}
    end
  end

  # --- Internal Algorithmic Classifiers ---

  defp determine_severity_prefix(c, lines) do
    cond do
      c > 15 or lines > 1000 -> "Infinite"
      c >= 5 -> "Runaway"
      true -> "Stray"
    end
  end

  defp determine_defect_typology(true, _, _), do: "Compiler Threat"
  defp determine_defect_typology(_, true, _), do: "Conflict Abomination"
  defp determine_defect_typology(_, _, "memory_leak"), do: "Zombie Function"
  defp determine_defect_typology(_, _, "infinite_loop"), do: "Infinite Loop"
  defp determine_defect_typology(_, _, _), do: "Asynchronous Phantom"

  defp assign_status_ailment("Compiler Threat"), do: "XP_BLOCK"
  defp assign_status_ailment("Conflict Abomination"), do: "STAMINA_DRAIN"
  defp assign_status_ailment("Infinite Loop"), do: "THREAD_LOCKDOWN"
  defp assign_status_ailment(_), do: "GOLD_DRAIN"

  defp update_raid_monsters(state, project_hash, monster_id, monster_payload) do
    case Map.get(state.active_raids, project_hash) do
      nil -> state
      raid ->
        updated_monsters = Map.put(raid.active_monsters, monster_id, monster_payload)
        updated_raid = %{raid | active_monsters: updated_monsters}
        %{state | active_raids: Map.put(state.active_raids, project_hash, updated_raid)}
    end
  end
end
