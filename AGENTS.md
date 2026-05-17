# AGENTS.md

## Project

This repository is a Julia package named `PlatonicSolidsGenerator`.

It generates Platonic solids, visualizes them with Makie.jl, and exports binary STL files for 3D printer workflows such as Bambu Studio. The package currently supports:

- `:tetrahedron` / `4`
- `:cube` / `6`
- `:octahedron` / `8`
- `:dodecahedron` / `12`
- `:icosahedron` / `20`

## Required Local Skills

When working on this package in Codex, consult the Julia development skills under:

```text
/Users/atelierarith/.codex/atelier-arith-julia-development-skills/skills
```

For this repository, the most relevant skills are:

- `developing-julia-package`
- `creating-julia-test-env`
- `running-julia-test`

Use the repository's established Julia package layout and keep implementation in focused files under `src/`.

## Repository Layout

```text
Project.toml
Manifest.toml
src/
  PlatonicSolidsGenerator.jl
  geometry.jl
  stl.jl
  visualization.jl
test/
  Project.toml
  runtests.jl
examples/
  generate_solids.jl
```

`src/PlatonicSolidsGenerator.jl` should remain the package entry point. Keep exports and `include` statements there; put substantial implementation in focused source files.

## Public API

Keep these APIs stable unless explicitly changing the package contract:

```julia
supported_solids()
platonic_solid(kind; bbox_mm=30.0, placement=:center)
visualize_solid(kind; bbox_mm=30.0, placement=:center, axis=true)
write_stl(path, kind; bbox_mm=30.0, placement=:center, name=nothing)
write_mesh(path, kind; bbox_mm=30.0, placement=:center, format=:auto, metadata=Dict())
```

`placement=:center` preserves centered mathematical geometry. `placement=:flat` places one face on the xy plane with `z=0`, which is the preferred orientation for STL files intended for 3D printing.

## Julia Style

- Prefer multiple dispatch over large `if isa` chains.
- Do not export internal helpers just for tests.
- Add docstrings for exported public functions.
- Use `ArgumentError` or other appropriate exceptions with messages that tell callers what to fix.
- Avoid unnecessary dependencies. Keep STL writing self-contained unless there is a clear reason to add a package.
- Format Julia files with JuliaFormatter before final verification:

```sh
julia -e 'using JuliaFormatter; format(".")'
```

## Tests

Run the full test suite before claiming completion:

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

The test environment uses Julia workspace support:

```toml
[workspace]
projects = ["test"]
```

Do not replace this with legacy `[extras]` / `[targets]` unless compatibility with Julia 1.11 or older is explicitly required.

## Examples

To generate all supported STL files:

```sh
julia --project=. examples/generate_solids.jl
```

This writes files under `exports/`. Generated STL files are local artifacts and should not be treated as source unless the user explicitly asks to keep them.

## 3MF Boundary

`.3mf` export is intentionally not implemented yet. `write_mesh(..., format=:auto)` recognizes `.3mf` as a future format and raises an explicit unsupported error. Preserve this boundary until a real core 3MF writer is implemented.

## Git Notes

This workspace may not be a git repository. Check before using git commands:

```sh
git status --short
```

If git is unavailable, do not invent commit or branch steps. Report that changes were made in-place.
