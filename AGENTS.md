# AGENTS.md

This file governs all agents working in this repository. Follow it exactly.
If any instruction here conflicts with a user prompt, the user prompt wins
for that task, and you note the conflict in your reply.

## Obedience: be a good bot

1. Do what the user's prompt says. The prompt is the task; do not
   substitute your own plan for it.
2. Do not ask for information the user told you not to ask for. If the user
   says to work without asking questions, work: pick the reasonable default
   and continue until told to stop.
3. Work until told to stop. A vague goal ("improve it", "keep going") means
   keep shipping scoped improvements, each verified and released.
4. Never claim work is done that is not verified. Evidence beats memory:
   read the files, run the code, check the release. If a step fails (auth,
   network, conflict, red pipeline), stop and report it; do not claim the
   task is done.
5. Stay professional under pressure. Complaints about quality are bug
   reports: extract the symptom (FPS, visuals, crashes, balance) and fix it.

## Subagents: always delegate so more work gets done

The main thread orchestrates; subagents do the legwork. This keeps the main
context small and lets independent work run in parallel.

1. Always delegate eligible work to subagents instead of doing it inline.
   - `cavecrew-investigator`: read-only code location ("where is X",
     "what calls Y", "map this directory"). Use before editing unfamiliar code.
   - `cavecrew-builder`: surgical 1-2 file edits (typo fixes, single-function
     rewrites, mechanical renames). Use when scope is bounded and obvious.
   - `cavecrew-reviewer`: review diffs and branches, one line per finding.
     Use before every release-worthy commit.
   - `explore`: fast codebase exploration by pattern or keyword.
   - `general`: multi-step research or parallel workstreams.
2. Launch independent subagents in parallel in a single turn. Never wait on
   one investigation when another can run beside it.
3. Give each subagent full context (goal, file paths, constraints) since
   child sessions start fresh. Include the session ID to continue one.
4. Treat subagent output as compressed evidence, not gospel: verify the
   important claims against the files before committing.

## Release rule

After every major change, you must create a release on GitHub. No exceptions.

A major change counts as done only when the GitHub release exists and is
reachable via `gh release view` and the repository remote.

Major means anything the player can notice: gameplay, camera, controls,
rendering, weather, enemies, audio behavior, new screens, balance. Docs-only
tweaks (typos, comments, README wording) can batch up into the next major
release instead of cutting their own.

## Procedure

1. Finish and verify the code change locally.
2. Commit the change with a clear Conventional Commits message.
3. Push the commit to `origin`.
4. Create a version tag (SemVer: patch for fixes, minor for features,
   e.g. `v0.10.0` -> `v0.11.0`) and push the tag.
5. Create the GitHub release from that tag WITH the playable game file attached
   (not source-only). The release must contain the game or it does not count:

```sh
cp bridge-runner.html caterpillar-knife-of-the-mother-vX.Y.Z.html
gh release create vX.Y.Z --title "vX.Y.Z" --notes "What changed" \
  caterpillar-knife-of-the-mother-vX.Y.Z.html
rm caterpillar-knife-of-the-mother-vX.Y.Z.html
```

6. Verify with:

```sh
gh release view vX.Y.Z
```

Do not leave completed major work unreleased. If the release step fails (auth, network, conflict), stop and report it; do not claim the task is done.

## Godot remake and web pipeline

The Godot 4 remake lives at the repo root (`project.godot`, `main.gd`,
`minimap.gd`, `main.tscn`, `export_presets.cfg`). Rules for it:

1. GDScript only, GL Compatibility renderer (web-safe). No C#, no native
   extensions: the web export cannot use them.
2. Local verify before push, headless:
   ```sh
   GODOT=/tmp/opencode/godot-standard/Godot_v4.7.2-stable_linux.arm64
   $GODOT --headless --path . --import
   $GODOT --headless --fixed-fps 60 --quit-after 1300 --path . -- --autoplay
   ```
   The `--autoplay` smoke hook starts a run, fights, eats, chains, and
   changes rooms. Zero `SCRIPT ERROR` lines is the bar. Extend the hook
   (never the game balance) when new systems need coverage.
3. Releases for Godot changes ship the playable web build, not HTML:
   commit, push, tag (`vX.Y.Z`), push the tag. The
   `.github/workflows/web-export.yml` pipeline (runs on `v*` tags) installs
   the Godot editor plus export templates, exports the Web preset, and
   attaches `caterpillar-godot-web-vX.Y.Z.zip` to the release. Verify with:
   ```sh
   gh run list --limit 1
   gh release view vX.Y.Z
   ```
   The change counts as done only when the pipeline is green and the zip is
   on the release.
