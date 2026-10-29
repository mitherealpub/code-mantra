defmodule CodeMantra.PersistenceDaemon do
  use GenServer
  require Logger

  # Visual Base32 alphabet: Exactly 32 characters, completely omitting ambiguous symbols (0, O, 1, l, I)
  @alphabet "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
  @alphabet_chars String.graphemes(@alphabet)
  @base 32

  # --- Client API ---

  @doc """
  Starts the standalone PersistenceDaemon process.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, %{}, opts)
  end

  # --- GenServer Callbacks ---

  @impl true
  def init(state) do
    Logger.info("[ACTOR 4: PERSISTENCE_DAEMON] Automated background save checkpoints and runic encryption schemas online.")
    {:ok, state}
  end

  @impl true
  def handle_cast({:queue_snapshot, user_id, player_stats, metrics}, state) do
    # 1. Isolate vital stat parameters
    level = player_stats.level || 1
    gold = player_stats.gold || 0
    title_hash = player_stats.title_hash_id || 0
    file_node_id = get_in(metrics.raw_telemetry, ["buffer_context", "file_node_id"]) || 1

    # 2. Serialize integers into deterministic, fixed-width custom Base32 data blocks
    block_lvl   = encode_int(level, 4)
    block_gold  = encode_int(gold, 6)
    block_title = encode_int(title_hash, 6)
    block_zone  = encode_int(file_node_id, 4)

    raw_payload = "#{block_lvl}#{block_gold}#{block_title}#{block_zone}"

    # 3. Compute a secure 4-character cyclic checksum via SHA-256 to stop local string modification
    checksum_hash = :crypto.hash(:sha256, raw_payload) |> Base.encode16()
    {checksum_int, _} = Integer.parse(String.slice(checksum_hash, 0, 8), 16)
    block_checksum = encode_int(rem(checksum_int, 100_000), 4)

    # 4. Synthesize the final hyphenated 24-character Mantra save token
    full_mantra = "#{raw_payload}#{block_checksum}"
    formatted_mantra = format_with_hyphens(full_mantra)

    # 5. Broadcast automated tracking log down to the specific user channel workspace
    # CodeMantraWeb.Endpoint.broadcast!("developer_workspace:#{user_id}", "guru_snapshot", %{
    #   mantra: formatted_mantra,
    #   terminal_banner: """
    #   ============================================================
    #   [GURU DAEMON LOG]: System stability matched. Save cached.
    #   CURRENT MANTRA: #{formatted_mantra}
    #   Write down this rune. If your machine crashes, boot from here.
    #   ============================================================
    #   """
    # })

    {:noreply, state}
  end

  @impl true
  def handle_call({:verify_and_boot, mantra}, _from, state) do
    clean_mantra = mantra |> String.replace("-", "") |> String.upcase()

    if String.length(clean_mantra) == 24 do
      raw_payload = String.slice(clean_mantra, 0, 20)
      provided_checksum = String.slice(clean_mantra, 20, 4)

      # Recalculate checksum verification bound
      checksum_hash = :crypto.hash(:sha256, raw_payload) |> Base.encode16()
      {checksum_int, _} = Integer.parse(String.slice(checksum_hash, 0, 8), 16)
      expected_checksum = encode_int(rem(checksum_int, 100_000), 4)

      if provided_checksum == expected_checksum do
        # Hydrate internal statistics matrices safely from verified Base32 blocks
        decoded_stats = %{
          level: decode_str(String.slice(clean_mantra, 0, 4)),
          gold: decode_str(String.slice(clean_mantra, 4, 10)),
          title_id: decode_str(String.slice(clean_mantra, 10, 16)),
          zone_id: decode_str(String.slice(clean_mantra, 16, 20))
        }
        {:reply, {:ok, decoded_stats}, state}
      else
        {:reply, {:error, :checksum_mismatch}, state}
      end
    else
      {:reply, {:error, :invalid_length}, state}
    end
  end

  # --- Custom Base32 Bit-Packing Helper Utilities ---

  defp encode_int(num, min_len) do
    do_encode(num, [])
    |> String.pad_leading(min_len, "2")
    |> String.slice(0, min_len)
  end

  defp do_encode(0, []), do: "2"
  defp do_encode(0, acc), do: Enum.join(acc)
  defp do_encode(num, acc) do
    rem_val = rem(num, @base)
    quotient = div(num, @base)
    char = Enum.at(@alphabet_chars, rem_val)
    do_encode(quotient, [char | acc])
  end

  defp decode_str(str) do
    str
    |> String.graphemes()
    |> Enum.reduce(0, fn char, acc ->
      index = Enum.find_index(@alphabet_chars, &(&1 == char)) || 0
      acc * @base + index
    end)
  end

  defp format_with_hyphens(str) do
    str
    |> String.graphemes()
    |> Enum.chunk_every(4)
    |> Enum.map(&Enum.join/1)
    |> Enum.join("-")
  end
end
