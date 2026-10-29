defmodule CodeMantra.EconomyLedger do
  use GenServer
  require Logger
  alias CodeMantra.ProgressionBalancer

  # --- Client API ---

  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{player_inventories: %{}}, opts)
  end

  @doc """
  Processes an item purchase transaction if the player has sufficient gold and meets level thresholds.
  """
  def purchase_item(pid, user_id, item_id, current_player_stats) do
    GenServer.call(pid, {:purchase_item, user_id, item_id, current_player_stats})
  end

  @doc """
  Triggers an item consumption event, applying passive buffs or purging active status ailments.
  """
  def consume_item(pid, user_id, item_id, current_player_stats) do
    GenServer.call(pid, {:consume_item, user_id, item_id, current_player_stats})
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(state) do
    Logger.info("[ACTOR 8: ECONOMY_LEDGER] Town Merchant and Apothecary transactional engines online.")
    {:ok, state}
  end

  @impl true
  def handle_call({:purchase_item, user_id, item_id, player}, _from, state) do
    with {:ok, item} <- fetch_item(item_id),
         :ok <- check_level_requirement(player.level, item.min_level),
         :ok <- verify_funds(player.gold, item.cost) do
      
      # 1. Deduct gold and add item to state inventory list
      new_gold = player.gold - item.cost
      user_inv = Map.get(state.player_inventories, user_id, [])
      new_inv = [item_id | user_inv]
      
      updated_state = put_in(state.player_inventories[user_id], new_inv)
      updated_player = Map.put(player, :gold, new_gold)

      Logger.info("[ECONOMY_LEDGER] User #{user_id} successfully purchased #{item.name} for #{item.cost} Gold.")
      {:reply, {:ok, updated_player}, updated_state}
    else
      {:error, reason} -> {:reply, {:error, reason}, state}
    end
  end

  @impl true
  def handle_call({:consume_item, user_id, item_id, player}, _from, state) do
    user_inv = Map.get(state.player_inventories, user_id, [])

    if item_id in user_inv do
      # 1. Drop item from player inventory array
      new_inv = List.delete(user_inv, item_id)
      updated_state = put_in(state.player_inventories[user_id], new_inv)

      # 2. Evaluate item side-effects and execute mutation logic loops
      {:ok, item} = fetch_item(item_id)
      updated_player = apply_item_effects(item_id, player)

      # 3. Schedule async debuff timers if item triggers a later performance penalty
      schedule_delayed_effects(user_id, item_id)

      Logger.info("[ECONOMY_LEDGER] User #{user_id} consumed #{item.name}. Status effects dispatched.")
      {:reply, {:ok, updated_player}, updated_state}
    else
      {:reply, {:error, :item_not_in_inventory}, state}
    end
  end

  @impl true
  def handle_info({:apply_tincture_crash, user_id}, state) do
    Logger.warn("[ECONOMY_LEDGER] Caffeine Overclock expired for user #{user_id}. Triggering 'Jittery Syntax' debuff.")
    
    # Broadcast status ailment block down channel to force 20% deletion penalties
    # CodeMantraWeb.Endpoint.broadcast!("developer_workspace:#{user_id}", "status_ailment", %{debuff: "JITTERY_SYNTAX"})
    
    {:noreply, state}
  end

  # --- Internal Transaction Helper Utilities ---

  defp fetch_item("caffeine_tincture"), do: {:ok, %{name: "Caffeine Overclock Tincture", cost: 150, min_level: 1}}
  defp fetch_item("garbage_collector"), do: {:ok, %{name: "Elixir of Garbage Collection", cost: 300, min_level: 6}}
  defp fetch_item("pipeline_defib"),   do: {:ok, %{name: "Pipeline Defibrillator Salt", cost: 500, min_level: 16}}
  defp fetch_item("hot_reload"),       do: {:ok, %{name: "Hot-Reload Catalyst", cost: 1200, min_level: 31}}
  defp fetch_item(_), do: {:error, :item_not_found}

  defp check_level_requirement(lvl, req) when lvl >= req, do: :ok
  defp check_level_requirement(_, _), do: {:error, :insufficient_mastery_tier}

  defp verify_funds(gold, cost) when gold >= cost, do: :ok
  defp verify_funds(_, _), do: {:error, :insufficient_gold_balance}

  defp apply_item_effects("caffeine_tincture", player) do
    # Temporarily forces 1.5x flow modifiers centrally inside Actor 3 calculations
    Map.put(player, :active_status_buff, "FLOW_OVERCLOCK")
  end

  defp apply_item_effects("pipeline_defib", player) do
    # Instantly purges active build block penalties without demanding a successful unit test
    Map.put(player, :status_ailments, List.delete(player[:status_ailments] || [], "SHAME_OF_RED_BUILD"))
  end

  defp apply_item_effects(_, player), do: player

  defp schedule_delayed_effects(user_id, "caffeine_tincture") do
    # Schedule a "Caffeine Crash" inside the processing grid after 15 minutes (900000ms)
    Process.send_after(self(), {:apply_tincture_crash, user_id}, 900_000)
  end
  defp schedule_delayed_effects(_, _), do: :ok
end
