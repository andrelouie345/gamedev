# AI Log

## Step 1a - first-person touch controller

- **What I asked:** Build a first-person touch controller and a greybox arena only.
- **What was produced:** A Godot 4 project with an Android landscape setting, one simple arena, touch movement/look/fire controls, and desktop keyboard/mouse controls for testing.
- **What I changed:** I confirmed the project opens and runs; no other user-side changes were reported.

## Step 1b - targets, shooting, score, and timer

- **What I asked:** Continue with the next project step after confirming the first-person controller and arena work.
- **What was produced:** Ten static targets in Level 1, camera-centered raycast shooting, a 60-second countdown, score/goal HUD, and clear/timeout feedback.
- **What I changed:** No additional user-side code changes were reported for this step yet.

## Step 1c - saved campaign progress

- **What I asked:** Continue to the next planned step after testing Step 1b.
- **What was produced:** A `GameState` autoload that loads and saves campaign unlocks and best stars with `ConfigFile` in `user://progress.cfg`. Clearing an unlocked level saves its star result and unlocks the next level, up to Level 5.
- **What I changed:** No additional user-side code changes were reported for this step yet.

## Step 1d - level select, results, and campaign levels

- **What I asked:** Continue after testing saved progress.
- **What was produced:** A level-select screen with locked-level indicators and saved stars; Retry, Next, and Menu result buttons; Levels 2-5 reuse the original arena. Level 2 increases the target count, Level 3 has moving bots, Level 4 has two waves of bots that shoot back, and Level 5 ends with a tougher boss bot.
- **What I changed:** No additional user-side code changes were reported for this step yet.

## Step 1e - mode select, versus bot, pause, and sound

- **What I asked:** Continue after testing the campaign levels and result flow.
- **What was produced:** Offline Campaign and Versus Bot selection; a SimpleAI opponent with per-level score delay and accuracy; pause controls for Resume, Restart, saved Sound on/off, and Quit to Menu; versus results that do not alter campaign progress.
- **What I changed:** No additional user-side code changes were reported for this step yet.

## Step 1f - same-Wi-Fi online score race

- **What I asked:** Continue with the online multiplayer step.
- **What was produced:** Host/join lobby over ENet, seeded identical target layouts, small target-index score events, host-authoritative score and winner decisions, a five-second join timeout, disconnect handling, and online result screens kept separate from campaign saves.
- **What I changed:** No additional user-side code changes were reported for this step yet.

## Step 1g - title screen, credits, and Android export

- **What I asked:** Continue with the final planned project step.
- **What was produced:** A title screen with Play, Credits, and Quit; credits accessible from the title and mode-selection screens; a credits document; and Android export and phone-test instructions. The project now starts at the title screen.
- **What I changed:** No additional user-side code changes were reported for this step yet.

## Follow-up — first-person assets and desktop touch testing

- **What was requested:** Create and integrate original low-poly first-person
  AK-47/arms and practice-target assets, improve shooting/range gameplay, and
  enable testing the mobile touch controls from a PC.
- **What was added:** Original textured GLB assets and a reproducible generator;
  weapon idle/fire/reload animations; target silhouettes and bullseyes; ammo,
  reload, recoil, muzzle flash, scoring and progression details; range geometry;
  and mouse-to-touch emulation. The desktop input path leaves emulated mouse
  events to the touch controls.
- **Validation:** Godot 4.7.2 headless imports and level/menu checks were run.
  Weapon, ammo/reload, hit scoring, headshot and combo behavior were exercised
  in an engine-level test. No Android device test was performed.

## Follow-up — ITSD 85 audit preparation

- **What was requested:** Audit the existing project against the supplied R1–R10
  checklist before further changes, preserve existing game systems, and prepare
  project/documentation/evaluation materials without fabricating team or test
  evidence.
- **What was added:** `docs/PROJECT_AUDIT.md`, a README, a GDD, blank consent and
  evaluation templates, a phone compatibility matrix, an original app icon,
  IPv4 validation and LAN-address display in the online lobby, clearer level
  introductions, a background music/effect system with original generated
  audio, online-leave confirmations, and updated Android/credits guidance and
  ignore rules.
- **Validation:** Godot 4.7.2 headless checks loaded all five level objective
  screens and the title, mode, level-select, lobby, pause, results and credits
  scenes. IPv4 validation was exercised. The official PDF, two-device tests,
  Android phone tests and participant results were not available.
