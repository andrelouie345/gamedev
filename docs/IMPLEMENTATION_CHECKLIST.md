# Implementation and Verification Checklist

This file is the handoff checklist for the current Arena Shooter project. It
records what is present in the repository separately from what has actually
been verified. A checked implementation item is not proof of a complete
playthrough, device test, or user evaluation.

For requirement-by-requirement audit notes, see
[PROJECT_AUDIT.md](PROJECT_AUDIT.md). Read the project files and rerun the
relevant test before making new claims about their current state.

## Implemented in the project

- [x] Godot 4.7 project with title, mode, level-select, lobby, pause, results,
  and credits screens.
- [x] Five campaign levels with increasing target, movement, wave, and boss
  challenges; level introductions show the objective and time limit.
- [x] Campaign and Versus Bot modes, plus an ENet host-and-join score race.
- [x] First-person player controls, touch-control UI, firing, recoil, ammo, and
  reload behavior.
- [x] Original low-poly AK/arms, silhouette, and bullseye GLB assets with
  associated textures in `assets/models/`.
- [x] Moving targets, head hitboxes, and score tracking for hits, accuracy,
  precision/headshots, combos, and misses.
- [x] Campaign stars and unlocks saved through Godot `ConfigFile` at
  `user://progress.cfg`.
- [x] Shooting-range scene details, original generated music and sound effects,
  a master sound toggle, and an original SVG app icon.
- [x] LAN address display and IPv4 join-input validation, connection feedback,
  and confirmation before leaving a lobby or active match.
- [x] Desktop mouse-to-touch emulation setting for testing touchscreen controls
  with a PC cursor.
- [x] Project, export, credits, AI-use, and playtest documentation, including
  blank evaluation templates.

## Automated checks recorded

- [x] Godot 4.7.2 headless checks loaded Levels 1–5 and the title, mode,
  level-select, lobby, pause, results, and credits screens.
- [x] Targeted checks covered weapon/ammo/precision-scoring behavior, IPv4
  validation, level objective introductions, audio-resource loading, and the
  desktop mouse-to-touch setting.
- [x] `git diff --check` completed without whitespace errors (a line-ending
  warning for `project.godot` was reported).

These are targeted engine checks, not a complete interactive test pass. See
[PROJECT_AUDIT.md](PROJECT_AUDIT.md) for the scope and recorded limitations.

## Still needs verification or supplied evidence

- [ ] Play through Campaign and Versus Bot, including success/failure results,
  navigation, level unlocks, and retry/next/menu flows.
- [ ] Close and relaunch the game to verify saved progress, stars, and sound
  preference persist.
- [ ] Verify first-person arm/weapon presentation and firing/reload animation
  quality in an interactive run; confirm the meshes and controls look correct.
- [ ] Test moving-target patterns, difficulty tuning, scoring, ammo limits, and
  timers in complete runs at each level.
- [ ] Test ENet host/join, scoring synchronization, restart, timeout, and
  disconnect recovery using two devices on the same Wi-Fi.
- [ ] Test offline modes with network connectivity disabled.
- [ ] Configure Android export with OpenJDK 17 and the Android SDK, export an
  APK, install it, and test landscape layout, touch controls, audio, and
  networking on real device(s).
- [ ] Complete the phone-compatibility matrix with actual device and test
  results.
- [ ] Evaluate audio and visuals in a normal (non-headless) interactive run.
- [ ] Obtain the authoritative ITSD 85 PDF/questionnaire and approved GDD
  template; fill forms only from those source materials.
- [ ] Obtain required approval and consent before recruiting participants.
- [ ] Record real playtest observations/results, make at least three
  evidence-based improvements, and retest with two new participants.
- [ ] Add verified team names, roles, contributions, screenshots, release URL,
  and research paper only when the actual approved materials are available.

Do not mark an item above complete based on implementation alone. Record the
test performed and its result in [PROJECT_AUDIT.md](PROJECT_AUDIT.md) or the
relevant playtest/evaluation record. Do not invent missing team details,
questionnaire wording, participant data, screenshots, test results, or release
links.

## Reusable instructions for future project work

Use or adapt this prompt when continuing the project:

> Before changing the Arena Shooter project, read `README.md`,
> `docs/IMPLEMENTATION_CHECKLIST.md`, and `docs/PROJECT_AUDIT.md`, then inspect
> the relevant current scenes/scripts/assets. Treat the checklist as a
> handoff, not proof: do not claim an item is tested unless its recorded
> evidence supports that claim. Preserve the existing project structure and
> unrelated worktree changes. Implement only the requested scope, run the
> smallest relevant Godot checks, and update the checklist/audit with actual
> results. Do not invent team, participant, device, questionnaire, screenshot,
> export, research, or release evidence. If a required source or decision is
> missing, state that clearly instead of guessing.
