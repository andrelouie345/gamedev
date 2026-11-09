# Project Audit — ITSD 85 Arena Shooter

**Audit date:** 2026-11-09. The R1–R10 table below reflects the project after
the post-audit preparation changes in this document.

## Scope and evidence

This audit covers the current Godot 4.7 project files and the supplied
acceptance checklist. The checklist's referenced official PDF was not present
in the repository during inspection, so the supplied text is the available
specification. No original ZIP was modified.

The project contains five level scenes, first-person player and target scenes,
campaign and bot modes, an ENet lobby and online race, UI screens, original
low-poly GLB and synthesized audio assets, and Godot headless-validation
history. The current Git worktree was clean at the start of this audit. Godot
headless scene-load checks were run for Levels 1–5 and the title, mode, level,
lobby, pause, results and credits screens. Weapon/ammo/precision scoring,
IPv4 validation and level-introduction content were runtime checked. These
checks do not replace full playthrough, network, export, phone, listening, or
participant testing.

## Existing implementation

| Area | Observed implementation | Current limitation |
|---|---|---|
| Game and levels | `project.godot` starts at the title screen. Levels 1–5 share the range and configure stationary/moving targets, waves, enemy attacks, boss health and limited reserve ammo. Level introductions display level number/name, objective, time and special mechanics. | Headless objective checks are not complete interactive playthroughs; the supplied checklist's full acceptance tests have not all been run. |
| Player controls | `Player.gd` supports WASD, camera look, firing, recoil, reloading and touch-control signals. `TouchControls.gd` draws a joystick, look region, fire and reload controls. Mouse-to-touch emulation is enabled in `project.godot`. | Real-device touch, landscape layout and sensitivity have not been tested on Android. |
| Targets and scoring | `Target.gd` and `BotEnemy.gd` provide moving silhouettes, head hitboxes and hit handling. `Level.gd` tracks hit count, accuracy, precision score, headshot/bullseye bonuses, combos and miss penalties. | Target hit behavior and scoring have only limited engine-level verification, not a complete player test across all modes. |
| Progress and results | `GameState.gd` uses `ConfigFile` at `user://progress.cfg` for campaign unlocks, stars and sound preference. Campaign level selection shows locked levels. Results offer Retry, Next and Menu. | Persistence across application restarts and every navigation/progression edge case have not been tested end-to-end. |
| Offline modes | Campaign and Versus Bot share the level-select flow. `SimpleAI.gd` configures bot timing and accuracy by level. Network activity is initiated from the lobby rather than ordinary level selection. | Airplane-mode testing has not been performed. |
| Online mode | `Net.gd` uses ENet, seeded target layouts, host-side score acceptance, duplicate-target tracking, match results, restart signals, a join timeout and disconnect handling. The lobby displays discovered LAN IPv4 addresses, validates IPv4 join input and confirms before leaving a lobby or active match. | Two-device tests have not been performed; in particular, host discovery, Wi-Fi/firewall behavior and full score synchronization remain unverified. |
| Arena and assets | The project includes original AK-47/arms, silhouette and bullseye GLBs with textures, original synthesized background music and effects, an arena scene, range details and an original target-themed SVG icon. Runtime and written credits describe the custom assets. | Audio behavior is wired in code but has not been evaluated by a listener or on an Android device. |
| Android export | Landscape is configured and `docs/ANDROID_EXPORT.md` describes a manual export process. | There is no checked-in Android export preset. Internet and Access Network State permissions, OpenJDK 17, Android SDK configuration and an exported APK have not been verified. No APK has been installed on a phone. |
| Project documentation and evaluation | `README.md`, `docs/GDD.md`, the audit, credits/export/AI logs, blank playtest forms, a phone compatibility matrix and a screenshots directory are present. | No official paper/template PDF was found. The official questionnaire items, participant details, screenshot evidence, research paper and actual playtest results remain unavailable. |
| Repository hygiene | `.gitignore` excludes `.godot/`, Android build output, export presets and common signing credentials. | Confirm ignore behavior against any future machine-specific export workflow before release. |

## R1–R10 audit

| Requirement | Implementation | Test performed | Evidence | Status |
|---|---|---|---|---|
| R1 — Five playable levels | Five level scenes configure increasing target, movement, wave and boss challenges. | Godot headless scene-load checks for Levels 1–5; not a full playthrough. | `scenes/levels/Level01.tscn`–`Level05.tscn`; `scripts/Level.gd`; `scripts/BotEnemy.gd` | PARTIAL |
| R2 — Clear objectives | Each level now names the level, objective/target count, time limit and special mechanics. | Headless checks instantiated all five levels and verified level-number/time introductions. | `scripts/Level.gd`; `scenes/levels/Level01.tscn`–`Level05.tscn` | PARTIAL |
| R3 — Results and navigation | Result data includes score, time, hit/accuracy, targets cleared and stars; Retry, Next and Menu handlers exist. | Static inspection; no complete victory/defeat navigation playthrough. | `scripts/Level.gd`; `scripts/GameState.gd`; `scripts/Result.gd` | PARTIAL |
| R4 — Level unlocking | Level 1 is the default unlock; only a successful campaign clear saves stars and unlocks the next level. Locked campaign entries are disabled. | Static inspection; unlock flows not tested through repeated application runs. | `scripts/GameState.gd`; `scripts/LevelSelect.gd` | PARTIAL |
| R5 — Saved progress | Unlocks, best stars and sound preference are read/written using `user://progress.cfg`. | Implementation inspected; persistence after closing and reopening was not tested. | `scripts/GameState.gd` | PARTIAL |
| R6 — Offline mode | Campaign and Versus Bot are available independently of lobby entry. | Static inspection; airplane-mode test not performed. | `scripts/ModeSelect.gd`; `scripts/SimpleAI.gd`; `scripts/Net.gd` | PARTIAL |
| R7 — Online multiplayer | ENet host/join, host-authoritative scoring, duplicate-score prevention, timeout, disconnect handling and restart are implemented. Lobby now displays available LAN IPv4 addresses and validates IPv4 join input. | Address validation was exercised in Godot; no two-device match was run. | `scripts/Net.gd`; `scripts/Lobby.gd`; `scenes/ui/Lobby.tscn` | PARTIAL |
| R8 — Mode selection and network errors | Mode choices, input validation, timeout and understandable connection-error paths exist. | Lobby and mode-selection scenes loaded headlessly; live connection failure/timeout was not exercised. | `scripts/ModeSelect.gd`; `scripts/Lobby.gd`; `scripts/Net.gd` | PARTIAL |
| R9 — Android compatibility | Landscape and touch controls are configured; mouse-to-touch emulation supports desktop input testing. | Godot desktop scene check only. No Android export, APK installation, real-device touch, or phone matrix test. | `project.godot`; `scripts/TouchControls.gd`; `docs/ANDROID_EXPORT.md` | NOT TESTED |
| R10 — Basic polish | Original textured models, range presentation, menu screens, a saved master sound toggle, generated background music/effects and an original app icon exist. | Godot headless checks; no listening evaluation, Android audio test, actual user evaluation or external playtest. | `assets/models/`; `assets/audio/`; `icon.svg`; `scenes/levels/RangeDetails.tscn`; `scripts/AudioManager.gd`; `scripts/Pause.gd`; `docs/CREDITS.md` | PARTIAL |

## Remaining work

1. Complete full interactive playthroughs and progression/persistence checks
   for Campaign and Versus Bot.
2. Test ENet host/join, host IP selection, scoring, restart and disconnect
   recovery between two devices on the same Wi-Fi.
3. Use the official supplied questionnaire PDF to fill the 15-item form.
   Recruit and test only after required instructor approval and consent.
4. Verify Android export with OpenJDK 17 and the Android SDK, then install the
   APK on real device(s), record the matrix and test landscape/touch/network
   behavior. Keep the export preset and signing secrets out of source control.
5. Collect actual external playtest evidence, analyze it, implement at least
   three evidence-based changes and retest those changes with two new
   participants.
6. Add authentic team roles/contributions, screenshots and the research paper
   only when those materials are supplied and approved.

## Unavailable evidence and release blockers

- The referenced authoritative PDF, its GDD template and its questionnaire
  were not present in the workspace.
- Team member names, roles, individual contributions and release links were
  not supplied.
- No APK, Android export preset, Android test phone, second multiplayer phone,
  external playtest participants, consent records, collected results,
  screenshots or research paper were available during this audit.
- Do not claim real-device or external-playtest compliance until the missing
  tests and evidence are provided.
