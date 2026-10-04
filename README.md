# ReqView.jl

A Julia prototype of the **Requirements View** for the IPOL product model.

## What it does

- Loads one Julia file per system/actor from `data/`.
- Links them into a single `Registry` — the in-memory source of truth.
- Exposes the two Excel-shaped views (`INCOMING`, `OUTGOING`) as tables.
- Builds the traceability graph: derivations, cascades, mutual allocations.
- Exports per-system Excel workbooks with both sheets.

## Design

- **Model** — structs (`Requirement`, `StatusRecord`, `SystemFile`, `Registry`).
- **Views** — `Vector{NamedTuple}`, consumed by DataFrames / XLSX / CSV.
- **Graphs** — built on demand from the registry via `Graphs.jl`.
- **Persistence** — `data/*.jl` are constructor calls; `to_julia` regenerates them.

The five linker stages (see `src/linker.jl`) enforce the invariants from the Requirements View document: 
unique identity, valid targets, valid derivations, status only for live allocations.

## Try it

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. scripts/demo.jl
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Layout

```
src/        library code
data/       one file per system — the authoritative input
scripts/    runnable demos
test/       unit tests
```