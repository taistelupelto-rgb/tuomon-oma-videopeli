# AGENTS.md

## Release rule

After every change, you must create a release on GitHub. No exceptions.

A change counts as done only when the GitHub release exists and is reachable via `gh release view` and the repository remote.

## Procedure

1. Finish and verify the code change locally.
2. Commit the change with a clear Conventional Commits message.
3. Push the commit to `origin`.
4. Create a version tag (SemVer, bump patch by default, e.g. `v0.9.0` -> `v0.9.1`) and push the tag.
5. Create the GitHub release from that tag:

```sh
gh release create vX.Y.Z --title "vX.Y.Z" --notes "What changed"
```

6. Verify with:

```sh
gh release view vX.Y.Z
```

Do not leave completed work unreleased. If the release step fails (auth, network, conflict), stop and report it; do not claim the task is done.
