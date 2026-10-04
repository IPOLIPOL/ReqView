# Graph projections. The Registry is the model; these functions build
# read-only graph views for traceability analysis and visualization.

"""
    derivation_graph(reg) -> (g, idx, ids)

Vertices = requirement ids. Edges go parent → child for each entry in
`derived_from`. Cycles are permitted (and meaningful when they occur).
"""
function derivation_graph(reg::Registry)
    ids = sort!(collect(keys(reg.requirements)))
    idx = Dict(id => i for (i, id) in enumerate(ids))
    g = SimpleDiGraph(length(ids))
    for r in values(reg.requirements)
        for p in r.derived_from
            add_edge!(g, idx[p], idx[r.id])
        end
    end
    return g, idx, ids
end

"""
    descendants(reg, root) -> Vector{String}

Every requirement reachable from `root` via derivation edges (inclusive).
Cycles are handled by the visited set.
"""
function descendants(reg::Registry, root::AbstractString)
    root = String(root)
    haskey(reg.requirements, root) ||
        throw(ArgumentError("unknown requirement: $root"))
    children = Dict{String,Vector{String}}()
    for r in values(reg.requirements)
        for p in r.derived_from
            push!(get!(children, p, String[]), r.id)
        end
    end
    seen  = Set{String}([root])
    stack = String[root]
    while !isempty(stack)
        x = pop!(stack)
        for c in get(children, x, String[])
            c in seen && continue
            push!(seen, c); push!(stack, c)
        end
    end
    return sort!(collect(seen))
end

"""
    ancestors(reg, leaf) -> Vector{String}

Every requirement that `leaf` (transitively) derives from, inclusive.
"""
function ancestors(reg::Registry, leaf::AbstractString)
    leaf = String(leaf)
    haskey(reg.requirements, leaf) ||
        throw(ArgumentError("unknown requirement: $leaf"))
    seen  = Set{String}([leaf])
    stack = String[leaf]
    while !isempty(stack)
        x = pop!(stack)
        for p in reg.requirements[x].derived_from
            p in seen && continue
            push!(seen, p); push!(stack, p)
        end
    end
    return sort!(collect(seen))
end

"""
    derivation_cycles(reg) -> Vector{Vector{String}}

Strongly connected components of the derivation graph with size > 1, plus
self-loops. Derivation is normally a DAG, so this is usually empty; the
function exists so unexpected cycles are surfaced rather than silently
flattened.
"""
function derivation_cycles(reg::Registry)
    g, _, ids = derivation_graph(reg)
    out = Vector{String}[]
    for scc in strongly_connected_components(g)
        if length(scc) > 1
            push!(out, sort!([ids[v] for v in scc]))
        else
            v = only(scc)
            has_edge(g, v, v) && push!(out, [ids[v]])
        end
    end
    return out
end

"""
    allocation_graph(reg) -> (g, nodes, idx)

A bipartite-ish view: requirement ids and system ids as vertices,
`requirement → target` as edges. This is where the "A asks B, B asks A"
circling appears, because the derivation graph alone is a DAG.
"""
function allocation_graph(reg::Registry)
    nodes = String[]
    index = Dict{String,Int}()
    node!(x) = haskey(index, x) ? index[x] :
        (push!(nodes, x); index[x] = length(nodes); index[x])
    for r in values(reg.requirements); node!(r.id); end
    for s in keys(reg.systems);       node!(s);    end
    g = SimpleDiGraph(length(nodes))
    for r in values(reg.requirements)
        for t in r.targets
            add_edge!(g, index[r.id], index[t])
        end
    end
    return g, nodes, index
end

"""
    mutual_allocations(reg) -> Vector{Tuple{String,String}}

Pairs of systems (A, B) with A < B such that some requirement owned by A is
allocated to B, and some requirement owned by B is allocated to A. These are
the "circle around each other" pairs of the narrative.
"""
function mutual_allocations(reg::Registry)
    edges = Set{Tuple{String,String}}()
    for r in values(reg.requirements)
        for t in r.targets
            push!(edges, (r.origin, t))
        end
    end
    pairs = Tuple{String,String}[]
    for (a, b) in edges
        (b, a) in edges && a < b && push!(pairs, (a, b))
    end
    return sort!(pairs)
end