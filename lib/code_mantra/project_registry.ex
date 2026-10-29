defmodule CodeMantra.ProjectRegistry do
  use GenServer
  alias CodeMantra.DungeonOrchestrator

  def start_link(opts), do: GenServer.start_link(__MODULE__, %{projects: %{}, dev_to_project: %{}}, opts)
  def init(state), do: {:ok, state}

  def register_developer(pid, user_id, project_hash) do
    GenServer.call(pid, {:register_dev, user_id, project_hash})
  end

  def handle_call({:register_dev, user_id, project_hash}, _from, state) do
    current_team = Map.get(state.projects, project_hash, MapSet.new())
    updated_team = MapSet.put(current_team, user_id)
    
    new_projects = Map.put(state.projects, project_hash, updated_team)
    new_dev_to_project = Map.put(state.dev_to_project, user_id, project_hash)
    
    party_size = MapSet.size(updated_team)
    is_now_team = party_size > 1
    
    if is_now_team do
      GenServer.cast(CodeMantra.DungeonOrchestrator, {:initialize_multiplayer_raid, project_hash, MapSet.to_list(updated_team)})
    end

    {:reply, {:ok, %{team_mode: is_now_team, current_party_size: party_size}}, %{state | projects: new_projects, dev_to_project: new_dev_to_project}}
  end
end
