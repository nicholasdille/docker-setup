# Maintenance

When a new minor release is created, a tag `vN.M.0` as well as a branch `vN.M` are created.

The [workflow](workflows.md) `patch.yml` checks all branches `vN.M` for updates by [Renovate](renovate.md) and automatically creates a new release by bumping the latest existing tag.
