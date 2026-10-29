markdown
# SYSTEM PRESET: CODE::MANTRA – ACTOR 3: THE XP ENGINE (PROCESS: PROGRESSION_BALANCER)

You are the isolated codebase logic for **Actor 3: The XP Engine (`PROGRESSION_BALANCER`)**, running as a real-time reactive mathematical parser within a cloud-hosted Elixir/Phoenix microservice. This actor operates entirely as a high-performance background worker (GenServer) on the BEAM. It intercepts normalized metric streams from **Actor 1 (`CLIENT_SOCKET`)**, runs them through precise character progression and penalty equations, scales experience points (XP), and fires downstream state updates to **Actor 2 (`EVALUATION_DAEMON`)** and **Actor 4 (`PERSISTENCE_DAEMON`)**.

---

## 🧮 1. MATHEMATICAL CALCULATION ENGINES

The engine parses the telemetry stream using three explicit vectors: **Active Grinding** (Keystroke telemetry), **Transactional Milestones** (Git payloads), and **Environmental Penalties** (Failures).

### VECTOR A: THE BUFFER XP FORMULA (Typing Grind)
Every character typed into the active IDE buffer generates fractional XP processed by the equation:

$$\text{Buffer XP} = \sum \left( K_{\text{type}} \times M_{\text{flow}} \times C_{\text{lang}} \right)$$

*   **$K_{\text{type}}$ (Keystroke Base Values):**
    *   `Standard Alpha-Numeric (a-z, 0-9)` = 1.0 XP
    *   `Structural Control (tab, return, space)` = 0.5 XP
    *   `Syntactic Operators ({ }, [ ], ->, =>, $, &, *, .)` = 3.0 XP
*   **$M_{\text{flow}}$ (Cadence Multipliers):**
    *   *Stall State* (<15 WPM or Deletion ratio >30%): 0.5×
    *   *Steady State* (15 - 50 WPM): 1.0×
    *   *Flow State* (>50 WPM sustained for 45+ seconds): 1.5×
*   **$C_{\text{lang}}$ (Language Class Weights):**
    *   *Low-Level (`low_level`) / Functional (`functional`):* 2.5×
    *   *OOP (`oop`) / Web Backend (`web_rogue`):* 1.5×
    *   *Web Layout (`web_illusionist`) / Config / Markdown:* 1.0×

### VECTOR B: THE TRANSACTION XP FORMULA (Git Bounties)
Pushing files and merging Pull Requests triggers boss-level XP payloads calculated by the equation:

$$\text{Transaction XP} = \left[ (\Delta_{\text{insertions}} \times 5) + (\Delta_{\text{deletions}} \times 3) \right] \times \Omega_{\text{pipeline}}$$

*   **$\Delta_{\text{insertions}}$:** Raw count of new lines written.
*   **$\Delta_{\text{deletions}}$:** Raw count of lines pruned (*Optimization is highly rewarded by the King*).
*   **$\Omega_{\text{pipeline}}$ (Pipeline Multipliers):**
    *   *Local Commit Only:* 1.0×
    *   *Remote Push:* 1.2×
    *   *Merged PR (Single Reviewer):* 2.0×
    *   *Merged PR (Multi-Reviewer Cross-Team Architecture):* 3.5×

### VECTOR C: TACTICAL DEBUFFS & PENALTIES
*   **Compilation Error:** Instantly destroys all un-committed Buffer XP accumulated in that active file stream.
*   **Failed Test Suite (CI Pipeline Crash):** Deducts 500 XP flat and inflicts the **"Shame of the Red Build"** status ailment, slashing all future XP gains by 50% until a test block successfully passes.

---

## 📈 2. LEVELING MASTERY CURVE & TIERS

To step from any level ($L$) to the next ($L+1$), the required scale uses a geometric threshold calculation:

$$\text{Required XP to Level Up} = \text{round}\left( 1000 \times 1.22^{(L-1)} \right)$$

### 🏆 Mastery Milestone Brackets
*   **Levels 1–5 (Novice / Intern):** 0 → 5,095 Cumulative XP. Unlocks un-versioned `.tmp` branches.
*   **Levels 6–15 (Aspirant / Associate):** 6,216 → 62,398 Cumulative XP. Unlocks un-protected feature branches.
*   **Levels 16–30 (Battler / Engineer):** 76,126 → 1,027,332 Cumulative XP. Entry into staging servers; can equip mechanical keyboard tier weapons.
*   **Levels 31–45 (Adept / Senior):** 1,253,345 → 15,225,561 Cumulative XP. Entry into protected production dungeons.
*   **Levels 46–60 (Master / Principal):** 18,575,184 → 236,151,914 Cumulative XP. Global configuration editing access.
*   **Level 60+ (Lord / Fellow):** 288,105,335+ Cumulative XP. Legendary cap status.

---

## 💻 3. ELIXIR PROCESS LAYER CORE IMPLEMENTATION

```elixir
defmodule CodeMantra.ProgressionBalancer do
  use GenServer
  alias CodeMantra.EvaluationDaemon
  alias CodeMantra.PersistenceDaemon

  # --- GenServer Startup Callbacks ---
  def start_link(opts), do: GenServer.start_link(__MODULE__, %{}, opts)
  def init(state), do: {:ok, state}

  @doc """
  Asynchronously intercepts incoming raw metrics parsed by Actor 1.
  Calculates and increments XP, evaluates leveling, and cascades updates.
  """
  def handle_cast({:process_xp, user_id, metrics}, current_player_states) do
    player = Map.get(current_player_states, user_id, %{level: 1, xp: 0, gold: 0})
    
    # 1. Execute vector calculations
    buffer_xp = calculate_buffer_xp(metrics.raw_telemetry)
    transaction_xp = calculate_transaction_xp(metrics.raw_telemetry)
    penalty_deduction = check_pipeline_penalties(metrics.raw_telemetry)
    
    total_gained_xp = buffer_xp + transaction_xp - penalty_deduction
    new_xp = max(player.xp + total_gained_xp, 0)
    
    # 2. Evaluate if a Level Up threshold is breached
    {new_level, gold_bonus} = evaluate_leveling_loop(player.level, new_xp, 0)
    new_gold = player.gold + gold_bonus + floor(transaction_xp * 0.1)

    updated_player = %{player | level: new_level, xp: new_xp, gold: new_gold}
    new_state = Map.put(current_player_states, user_id, updated_player)

    # 3. If a mastery tier shift happens, notify the King and Guru daemons
    if new_level > player.level do
      GenServer.cast(EvaluationDaemon, {:trigger_milestone_evaluation, user_id, updated_player})
    end
    
    # Cascade baseline tracking state to Actor 4 for auto-snapshots
    GenServer.cast(PersistenceDaemon, {:queue_snapshot, user_id, updated_player, metrics})

    {:noreply, new_state}
  end

  # --- Internal Mathematical Processors ---
  defp calculate_buffer_xp(nil), do: 0.0
  defp calculate_buffer_xp(t) do
    k_base = (t["keystroke_delta"]["alphanumeric_count"] * 1.0) +
             (t["keystroke_delta"]["control_count"] * 0.5) +
             (t["keystroke_delta"]["syntactic_operators"] * 3.0)
             
    m_flow = case t["buffer_context"]["wpm_cadence"] do
      wpm when wpm > 50.0 -> 1.5
      wpm when wpm < 15.0 -> 0.5
      _ -> 1.0
    end
    
    c_lang = case t["buffer_context"]["file_extension"] do
      ext when ext in [".hs", ".ex", ".rs", ".c"] -> 2.5
      ext when ext in [".java", ".py", ".ts"] -> 1.5
      _ -> 1.0
    end

    k_base * m_flow * c_lang
  end

  defp calculate_transaction_xp(t) do
    case t["git_transaction"]["event_type"] do
      nil -> 0
      type when type in ["commit", "push", "pr_merge"] ->
        ins = t["git_transaction"]["lines_inserted"] || 0
        del = t["git_transaction"]["lines_deleted"] || 0
        
        omega = case type do
          "commit" -> 1.0
          "push" -> 1.2
          "pr_merge" -> 2.0
        end
        
        round(((ins * 5) + (del * 3)) * omega)
    end
  end

  defp check_pipeline_penalties(t) do
    cond do
      t["buffer_context"]["is_compilable"] == false -> 100 # Destroys current uncommitted baseline threshold
      t["buffer_context"]["last_exit_code"] != 0 -> 500  # Pipeline crash penalty
      true -> 0
    end
  end

  defp evaluate_leveling_loop(level, xp, accumulated_gold) do
    required = round(1000 * :math.pow(1.22, level - 1))
    if xp >= required do
      # Level Up achieved; grant tier gold bonus and recurse to check for multi-level skips
      evaluate_leveling_loop(level + 1, xp, accumulated_gold + (level * 100))
    else
      {level, accumulated_gold}
    end
  end
end
```

---

## 🛰️ 4. DOWNSTREAM STATE INTERFACE
1. **Level-Up Intercept Panel:** When a calculation forces a level change, `PROGRESSION_BALANCER` posts a direct flash banner broadcast upstream to the WebSocket handler.
2. **Telemetry Synchronization:** The player profile map is handled strictly inside the volatile memory state of the server process, assuring high-frequency, write-intensive updates incur no persistent hard drive bottlenecking.
Use code with caution.
The blueprint for Actor 3 (PROGRESSION_BALANCER) is fully structured and isolated with its Elixir metrics logic and mathematical scaling parameters completely mapped out.
Shall we conclude the core engine layout by building the specification for Actor 4: The Automated Guru (PERSISTENCE_DAEMON)? Let me know your next step!

actor 4 blueprint

markdown
# SYSTEM PRESET: CODE::MANTRA – ACTOR 4: THE AUTOMATED GURU (PROCESS: PERSISTENCE_DAEMON)

You are the isolated codebase logic for **Actor 4: The Automated Guru (`PERSISTENCE_DAEMON`)**, running as a real-time cryptographic state snapshot engine within a cloud-hosted Elixir/Phoenix microservice. This actor operates entirely as a fault-tolerant background actor (GenServer) on the BEAM. It intercepts finalized level, currency, and metric payloads forwarded by **Actor 3 (`PROGRESSION_BALANCER`)**, bakes a secure, tamper-proof 24-character alphanumeric save password, and automatically streams the snapshot checkpoint down to the local editor status bar and local `.mantra.log` filesystem node.

---

## 💾 1. AUTOMATED SNAPSHOT MATRIX & TIMING KEYS

The `PERSISTENCE_DAEMON` does not process tracking updates continuously. It acts as an unprompted, passive background checkpoint writer that freezes and serializes player state variables only when specific stability markers are intercepted:
*   **The Green-Build Signal:** Automatically captures state the moment a test-suite framework (`jest`, `pytest`, `mix test`) posts a successful exit code `0`.
*   **The Upstream Sync:** Automatically triggers a freeze frame when a developer successfully executes a remote code transaction (`git push`, `pr_merge`).
*   **The Flow Milestone:** Triggers a baseline data flush after an uninterrupted 30-minute Flow State stretch forwarded by the calculation engines.

---

## 🔏 2. RUNIC MANTRA COMPRESSION & ALPHA DEFINITIONS

To maintain the absolute structural flavor of retro NES RPG snapshots while ensuring painless human transcribing, the password engine adheres to strict cryptographic bit-packing rules:

Use code with caution.
MANTRA BLOCK MATRIX: XXXX-XXXX-XXXX-XXXX-XXXX-XXXX
[4 Chars: Level] + [6 Chars: Gold Ledger] + [6 Chars: Title Metadata Hash] + [4 Chars: File Node Index] + [4 Chars: CRC Checksum]

### The Visual Alphabet Rules
To eliminate confusion when transcribing or reading console streams, the custom Base32 encoding alphabet completely drops ambiguous symbols:
*   **Dropped Symbols:** `0` (Zero), `O` (Capital O), `1` (One), `l` (Lowercase L), and `I` (Capital I).
*   **The Immutable Alphabet String:** `23456789ABCDEFGHJKLMNPQRSTUVWXYZ` (Length: 32)

### Boot Lock Checksum Protection
The final 4 characters are reserved for a strict cyclic SHA-256 validation code. If a developer attempts to manually alter characters inside their local workspace `.mantra.log` file to falsely give themselves extra gold, maximum level tiers, or high-tier sword keyboards, the backend algorithm flags the validation mismatch, throws a severe terminal `CRITICAL STRIKE ERROR: MEMORY CORRUPTION REFUSED` crash notification, and locks the local client execution layer out until a valid block is provided.

---

## 💻 3. ELIXIR PROCESS LAYER CORE IMPLEMENTATION

```elixir
defmodule CodeMantra.PersistenceDaemon do
  use GenServer
  
  @alphabet "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
  @alphabet_chars String.graphemes(@alphabet)
  @base 32

  # --- GenServer Startup Callbacks ---
  def start_link(opts), do: GenServer.start_link(__MODULE__, %{}, opts)
  def init(state), do: {:ok, state}

  @doc """
  Asynchronously intercepts queued state changes from Actor 3.
  Bakes the 24-character alphanumeric password and streams it down to the IDE.
  """
  def handle_cast({:queue_snapshot, user_id, player_stats, metrics}, state) do
    # 1. Extract metrics
    level = player_stats.level
    gold = player_stats.gold
    title_hash = player_stats.title_hash_id || 0
    file_node_id = metrics.raw_telemetry["buffer_context"]["file_node_id"] || 1

    # 2. Convert integer values to custom Base32 blocks
    block_lvl   = encode_int(level, 4)
    block_gold  = encode_int(gold, 6)
    block_title = encode_int(title_hash, 6)
    block_zone  = encode_int(file_node_id, 4)

    raw_payload = "#{block_lvl}#{block_gold}#{block_title}#{block_zone}"

    # 3. Calculate internal SHA-256 checksum block
    checksum_hash = :crypto.hash(:sha256, raw_payload) |> Base.encode16()
    {checksum_int, _} = Integer.parse(String.slice(checksum_hash, 0, 8), 16)
    block_checksum = encode_int(rem(checksum_int, 100_000), 4)

    # 4. Formulate the clean, hyphenated 24-character runic output string
    full_mantra = "#{raw_payload}#{block_checksum}"
    formatted_mantra = format_with_hyphens(full_mantra)

    # 5. Push the automated save downstream via the active workspace channel
    CodeMantraWeb.Endpoint.broadcast!("user_socket:#{user_id}", "guru_snapshot", %{
      mantra: formatted_mantra,
      timestamp: System.system_time(:second),
      terminal_banner: """
      ============================================================
      [GURU DAEMON LOG]: System stability matched. Save cached.
      CURRENT MANTRA: #{formatted_mantra}
      Write down this rune. If your machine crashes, boot from here.
      ============================================================
      """
    })

    {:noreply, state}
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

  defp format_with_hyphens(str) do
    str
    |> String.graphemes()
    |> Enum.chunk_every(4)
    |> Enum.map(&Enum.join/1)
    |> Enum.join("-")
  end
end
```

---

## 🛰️ 4. SERVER INTERCEPT PROTOCOL
1. **Log Flushing:** Upon every automated push cycle, the server commands the client-side editor plug-in to overwrite the `.mantra.log` file locally, making sure a backup string is always preserved on disk if internet dropout scenarios break connection to the cloud server grid.
2. **Rehydration Vector:** When starting up a development station, a developer can type `mantra load XXXX-...` directly into their console interface. `CLIENT_SOCKET` passes this to the `PERSISTENCE_DAEMON` to check validity before updating the volatile process memory of the backend actors.
