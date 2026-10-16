# AGENTS.md

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
