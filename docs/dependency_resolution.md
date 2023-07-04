# Dependency resolution

Dependencies are resolved by enumerating all requested tools. For every tool, dependencies (see `build_dependencies` and `runtime_dependencies` in [tool manifests](manifest.md)) are added to the final list of tools recursively.
