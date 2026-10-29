defmodule CodeMantra.ProgressionBalancer do
  use GenServer
  alias CodeMantra.PersistenceDaemon

  def start_link(opts), do: GenServer.start_link(__MODULE__, %{}, opts)
  def init(state), do: {:ok, state}

  def handle_cast({:process_xp, user_id, metrics}, state) do
    player = Map.get(state, user_id, %{level: 1, xp: 0, gold: 0})
    
    buffer_xp = calculate_buffer_xp(metrics.raw_telemetry)
    new_xp = player.xp + round(buffer_xp)
    new_level = evaluate_level(player.level, new_xp)
    
    updated_player = %{player | level: new_level, xp: new_xp}
    
    GenServer.cast(CodeMantra.PersistenceDaemon, {:queue_snapshot, user_id, updated_player, metrics})
    {:noreply, Map.put(state, user_id, updated_player)}
  end

  defp calculate_buffer_xp(nil), do: 0.0
  defp calculate_buffer_xp(t) do
    ops = get_in(t, ["keystroke_delta", "syntactic_operators"]) || 0
    alphas = get_in(t, ["keystroke_delta", "alphanumeric_count"]) || 0
    (alphas * 1.0) + (ops * 3.0)
  end

  defp evaluate_level(level, xp) do
    required = round(1000 * :math.pow(1.22, level - 1))
    if xp >= required, do: evaluate_level(level + 1, xp), else: level
  end
end
