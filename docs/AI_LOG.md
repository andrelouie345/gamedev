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
