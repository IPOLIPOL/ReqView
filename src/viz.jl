# Traceability visualization.
#
# Three projections of the same Registry, each answering a different question:
#
#   plot_derivation   — the cascade: how high-level needs refine into tasks.
#   plot_allocations  — the allocation relation: who owns, who implements.
#   plot_circulation  — the system-level flow: where two systems loop.
#
# All three share a single color map so a system can be followed by eye
# across every figure.

using GraphRecipes
using Plots
using Graphs

const _SYSTEM_PALETTE = [
    "#2F6DB5", "#2E8B57", "#D9822B", "#7A4FA3",
    "#C0392B", "#16A085", "#8E44AD", "#34495E",
]

"""
    system_colors(reg) -> Dict{String,String}

Deterministic color per system, alphabetical by id.
"""
function system_colors(reg::Registry)
    ids = sort!(collect(keys(reg.systems)))
    Dict(id => _SYSTEM_PALETTE[mod1(i, length(_SYSTEM_PALETTE))]
         for (i, id) in enumerate(ids))
end

_short(id::AbstractString) = replace(id, "-REQ-" => "-")

# ---------------------------------------------------------------------------
# Figure 1 — derivation tree
# ---------------------------------------------------------------------------

"""
    plot_derivation(reg; path="out/derivation.png")

Hierarchical view of the `derived_from` relation. Multiple parents per node
are drawn as converging branches (the DAG is *not* forced into a tree).
"""
function plot_derivation(reg::Registry; path::AbstractString="out/derivation.png")
    g, _, ids = derivation_graph(reg)
    cmap = system_colors(reg)
    labels = [_short(id) for id in ids]
    nodecolors = [cmap[reg.requirements[id].origin] for id in ids]

    p = graphplot(g;
        method      = :tree,
        names       = labels,
        nodecolor   = nodecolors,
        nodeshape   = :rect,
        nodesize    = 0.35,
        fontsize    = 7,
        linewidth   = 1.5,
        title       = "Derivation tree — cascade from needs to tasks",
        axis_buffer = 0.15,
    )
    mkpath(dirname(path))
    savefig(p, path)
    return path
end

# ---------------------------------------------------------------------------
# Figure 2 — allocation map (bipartite)
# ---------------------------------------------------------------------------

"""
    plot_allocations(reg; path="out/allocations.png")

Bipartite view: every requirement on the left, every system on the right,
an arrow for each allocation. Requirement node color = owning system.
"""
function plot_allocations(reg::Registry; path::AbstractString="out/allocations.png")
    req_ids = sort!(collect(keys(reg.requirements)))
    sys_ids = sort!(collect(keys(reg.systems)))
    all_ids = vcat(req_ids, sys_ids)
    index   = Dict(id => i for (i, id) in enumerate(all_ids))

    n = length(all_ids)
    g = SimpleDiGraph(n)
    for r in values(reg.requirements)
        for t in r.targets
            add_edge!(g, index[r.id], index[t])
        end
    end

    # Positions: requirements at x=0, systems at x=1, evenly spaced vertically.
    xpos = vcat(zeros(length(req_ids)), ones(length(sys_ids)))
    ypos = vcat(range(1.0, 0.0; length=length(req_ids)),
                range(1.0, 0.0; length=length(sys_ids)))

    cmap = system_colors(reg)
    nodecolors = vcat(
        [cmap[reg.requirements[id].origin] for id in req_ids],
        [cmap[id] for id in sys_ids],
    )
    shapes = vcat(fill(:rect,  length(req_ids)),
                  fill(:circle, length(sys_ids)))
    labels = vcat([_short(id) for id in req_ids], sys_ids)

    p = graphplot(g;
        x           = xpos,
        y           = ypos,
        names       = labels,
        nodecolor   = nodecolors,
        nodeshape   = shapes,
        nodesize    = 0.4,
        fontsize    = 7,
        linewidth   = 1.2,
        arrow       = true,
        title       = "Allocation map — what each requirement is allocated to",
        axis_buffer = 0.1,
    )
    mkpath(dirname(path))
    savefig(p, path)
    return path
end

# ---------------------------------------------------------------------------
# Figure 3 — system-to-system circulation
# ---------------------------------------------------------------------------

"""
    plot_circulation(reg; path="out/circulation.png")

Collapses every requirement into a single system → target system edge.
Two-way edges (the "circling" case) appear as paired arrows and are
highlighted in red.
"""
function plot_circulation(reg::Registry; path::AbstractString="out/circulation.png")
    sys_ids = sort!(collect(keys(reg.systems)))
    index   = Dict(id => i for (i, id) in enumerate(sys_ids))
    n       = length(sys_ids)
    g       = SimpleDiGraph(n)

    for r in values(reg.requirements)
        for t in r.targets
            add_edge!(g, index[r.origin], index[t])
        end
    end

    g_mut = SimpleDiGraph(n)
    for e in edges(g)
        has_edge(g, dst(e), src(e)) && add_edge!(g_mut, src(e), dst(e))
    end

    cmap = system_colors(reg)
    nodecolors = [cmap[id] for id in sys_ids]

    # Base layer — the full circulation, neutral grey.
    # NOTE: `edgecolor` must be a colour value (Symbol or Colorant),
    # never a String — GraphRecipes iterates Strings internally.
    p = graphplot(g;
        method      = :circular,
        names       = sys_ids,
        nodecolor   = nodecolors,
        nodeshape   = :circle,
        nodesize    = 0.6,
        fontsize    = 11,
        edgecolor   = :grey,
        linewidth   = 1.2,
        arrow       = true,
        axis_buffer = 0.15,
        size        = (1000, 900),
    )

    # Overlay layer — mutual pairs in red, thicker.
    if ne(g_mut) > 0
        graphplot!(p, g_mut;
            method    = :circular,
            names     = sys_ids,
            nodecolor = nodecolors,
            nodeshape = :circle,
            nodesize  = 0.6,
            fontsize  = 11,
            edgecolor = :red,
            linewidth = 3.0,
            arrow     = true,
        )
    end

    title!(p, "System circulation — red = mutual (A↔B) allocation")
    mkpath(dirname(path))
    savefig(p, path)
    return path
end