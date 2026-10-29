# 🔮 Code::Mantra

An asynchronous, real-time, gamified coding telemetry server built with **Elixir** and **Phoenix LiveView**. 

`Code::Mantra` merges the keystroke-tracking architecture of **Code::Stats** with the retro snapshot, password, and character progression mechanics of the classic NES RPG **Faxanadu**. Writing code serves as your core grinding mechanic, where individual programming languages act as distinct character classes, and your repositories become shared multiplayer dungeons.

---

## 🕹️ The Core Gameplay Loop

1. **The Telemetry Grind:** As you type in your IDE, rapid telemetry pulses dump XP into specific language tracks (`Elixir`, `Python`, `Rust`, etc.) and level up your **AI Companions** if you are utilizing LLM generators.
2. **The King's Coronation:** Accumulating XP does *not* automatically update your rank title or acknowledged level. In true *Faxanadu* fashion, you must explicitly **Visit the King** (or run into him during random ambient background events) to be knighted with a procedurally generated title based on your coding stats (e.g., `Level 7 Knight-Compiler: Optimized Elixir Artisan`).
3. **The Priest's Mantra Checkpoint:** To safeguard your progress, you must request a text-based **UUID Mantra** password from the Priest. The Priest will strictly **refuse** to seal your save state if you are hoarding unspent XP—you must visit the King and get fully crowned first.
4. **Cryptographic Co-op Dungeons:** When multiple developers open the same project workspace on their machines, the directory path is cryptographically hashed with a server salt into an anonymous signature (e.g., `REALM-4aef81`). If other party members are active in the same realm, every user receives a compounding **1% bonus XP multiplier per developer** via a dedicated registry-backed `GenServer` room.

---

## 📂 System Architecture Blueprint

```text
code_stats/
├── mix.exs                           # OTP app boot profile and system dependencies
├── config/
│   ├── config.exs                    # Global Phoenix, PubSub, and endpoint routing configurations
│   └── dev.exs                       # Local database credentials and development parameters
├── priv/repo/migrations/             # Database structural evolutions and composite indexes
├── lib/
│   ├── code_stats/                   # --- BACKEND INFRASTRUCTURE ---
│   │   ├── application.ex            # Main OTP Supervision tree (Registry & Dynamic Supervisors)
│   │   └── accounts/user.ex          # Global User schema definitions
│   ├── game_engine/                  # --- GAME ENGINE LOGIC ---
│   │   ├── king.ex                   # Procedural Rank Title Generator & XP math curves
│   │   ├── companion_king.ex         # AI Familiar Evolution calculations
│   │   ├── priest.ex                 # Mantra Snapshot Vault & Checkpoint validations
│   │   ├── priest_restore.ex         # Character timeline database rollback transaction matrix
│   │   ├── project_crypt.ex          # Cryptographic workspace path obfuscation loop
│   │   ├── party_room.ex             # Dynamic real-time Project Grouping GenServer
│   │   ├── orchestrator.ex           # Multiplier engine and transaction entry coordinator
│   │   ├── encounter_engine.ex       # Keystroke-driven Random Event roller
│   │   └── random_world_worker.ex    # Ambient background Cron loop worker
│   └── code_stats_web/               # --- FRONTEND (PURE LIVEVIEW) ---
│       ├── router.ex                 # LiveView and API pathway router map
│       ├── controllers/
│       │   └── pulse_controller.ex   # IDE Telemetry Ingestion HTTP POST handler
│       └── live/
│           ├── auth_gate_live.ex     # NES-style title screen password spawner & mantra login
│           ├── terminal_live.ex      # Interactive command console workspace HUD
│           ├── profile_live.ex       # Dual-Vector Character Card (Gravatar + Pixel Sprite Frame)
│           └── leaderboard_live.ex   # Indexed Arcade Scoreboard dashboard
└── test/game_engine/
    └── party_simulation_test.exs     # Complete concurrent player workspace integration test
```

---

## ⚡ Mathematical & Structural Specifications

*   **XP Progression Curve:** $\text{level} = \lfloor(\text{xp} / 1000)^{(1 / 1.5)}\rfloor$
*   **Party Scaling Modifier:** $1.0 + ((\text{party\_size} - 1) \times 0.01)$ capped at a maximum ceiling of $1.25$ ($+25\%$ bonus).
*   **Ambient Simulation Cycle:** A transient background loop execution wheel running on a randomized thread timer every `5..15` minutes to force unprompted promotions or drop free background Mantra snapshots to active database users.

---

## 🛠️ Cold-Boot Cold Setup

Ensure your local machine has **Erlang/OTP 26+**, **Elixir 1.16+**, and a running **PostgreSQL** instance.

```bash
# 1. Clone or place the codebase directory structure and navigate to root
cd code_stats

# 2. Fetch and compile all application dependencies
mix deps.get
mix deps.compile

# 3. Create the database, execute game migrations, and build high-performance composite indexes
mix ecto.setup

# 4. Execute the concurrent multi-user integration test suite
mix test

# 5. Bring the real-time server online inside an interactive Elixir shell session
iex -S mix phx.server
```

Once running, point your browser to `http://localhost:4000` to interact with the Auth Gate, or jump into `http://localhost:4000/terminal` to begin executing system commands.

---

## 🔌 IDE Pulse Payload Specification

External IDE plugins can stream text pulses to the ingestion engine by issuing an HTTP `POST` to `/api/v1/pulses` with a Bearer Token mapping to the active user session.

```json
{
  "pulse": {
    "language": "elixir",
    "xp": 120,
    "project_path": "/Users/developer/src/my_secret_repo",
    "is_ai_generated": false
  }
}
```
