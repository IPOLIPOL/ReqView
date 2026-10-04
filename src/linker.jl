# The linker: scan every SystemFile, produce a Registry, validate consistency.
# Five sequential pure stages. See the Requirements View document.

"""
    link!(reg, files)

Populate `reg` from a collection of `SystemFile`s. Each stage validates one
invariant; on violation a `LinkError` is raised with the stage name.
"""
function link!(reg::Registry, files::Vector{SystemFile})
    # Stage 1 — register systems
    for f in files
        haskey(reg.systems, f.id) &&
            throw(LinkError(:register_systems, f.id, "duplicate system id"))
        reg.systems[f.id] = f
    end

    # Stage 2 — flatten requirements; assert global id uniqueness
    for f in files
        for r in f.outgoing
            r.origin == f.id ||
                throw(LinkError(:flatten_requirements, r.id,
                    "origin=$(r.origin) does not match containing system $(f.id)"))
            haskey(reg.requirements, r.id) &&
                throw(LinkError(:flatten_requirements, r.id,
                    "duplicate requirement id across systems"))
            reg.requirements[r.id] = r
        end
    end

    # Stage 3 — every target must be a registered system
    for r in values(reg.requirements)
        for t in r.targets
            haskey(reg.systems, t) ||
                throw(LinkError(:validate_targets, r.id,
                    "unknown target system: $t"))
        end
    end

    # Stage 4 — every parent in derived_from must exist
    # (cycles are permitted; only dangling references are rejected)
    for r in values(reg.requirements)
        for p in r.derived_from
            haskey(reg.requirements, p) ||
                throw(LinkError(:validate_derivations, r.id,
                    "unknown parent requirement: $p"))
        end
    end

    # Stage 5 — attach status records, keyed by (req_id, target)
    for f in files
        for s in f.status
            s.target == f.id ||
                throw(LinkError(:attach_status, s.req_id,
                    "status target=$(s.target) does not match system $(f.id)"))
            r = get(reg.requirements, s.req_id, nothing)
            r === nothing &&
                throw(LinkError(:attach_status, s.req_id,
                    "status refers to unknown requirement"))
            s.target in r.targets ||
                throw(LinkError(:attach_status, s.req_id,
                    "status target=$(s.target) is not an allocation of $s.req_id"))
            reg.status[(s.req_id, s.target)] = s
        end
    end

    return reg
end

# ---------------------------------------------------------------------------
# Data loading: include each data/*.jl in an isolated module that has ReqView
# in scope, then call the function named after the file.
# ---------------------------------------------------------------------------

const _DATA_MODULE = Ref{Union{Nothing,Module}}(nothing)

function _data_module()
    m = _DATA_MODULE[]
    m === nothing || return m
    m = Module()
    # Bind the already-loaded ReqView module by reference — do not go
    # through the Pkg loader, which would search the registry.
    parent = @__MODULE__          # this is ReqView itself
    Core.eval(m, :(const ReqView = $parent))
    Core.eval(m, :(using .ReqView))
    _DATA_MODULE[] = m
    return m
end

"""
    load_data(dir)

Include every `*.jl` file in `dir`; each must define a zero-argument function
whose lowercased name matches the file basename:

    data/HVAC.jl  →  function hvac() :: SystemFile

Files starting with `_` are skipped.
"""
function load_data(dir::AbstractString)
    dir = abspath(dir)
    isdir(dir) || throw(ArgumentError("not a directory: $dir"))
    m = _data_module()
    files = SystemFile[]
    for path in sort(readdir(dir; join=true))
        base = basename(path)
        (endswith(base, ".jl") && !startswith(base, "_")) || continue
        fn = Symbol(lowercase(replace(base, ".jl" => "")))
        Base.include(m, path)
        f = Base.invokelatest(getfield, m, fn)
        push!(files, Base.invokelatest(f))
    end
    return files
end

"""
    build_registry(dir="data")

Convenience: load every system file from `dir` and run the linker.
"""
function build_registry(dir::AbstractString="data")
    reg = Registry()
    link!(reg, load_data(dir))
    return reg
end

# ---------------------------------------------------------------------------
# Write-back: emit the current Registry as data/*.jl files.
# ---------------------------------------------------------------------------

"""
    to_julia(reg, dir)

Regenerate each system file from the current Registry. This is the inverse of
`load_data` — same file format, no separate serialization.
"""
function to_julia(reg::Registry, dir::AbstractString)
    dir = abspath(dir)
    mkpath(dir)
    for (id, sys) in reg.systems
        path = joinpath(dir, id * ".jl")
        open(path, "w") do io
            println(io, "function ", lowercase(id), "() :: SystemFile")
            println(io, "    SystemFile(")
            println(io, "        ", repr(id), ",")
            println(io, "        ", repr(sys.name), ",")
            println(io, "        [")
            for r in sys.outgoing
                println(io, "            Requirement(")
                println(io, "                id           = ", repr(r.id), ",")
                println(io, "                origin       = ", repr(r.origin), ",")
                println(io, "                name         = ", repr(r.name), ",")
                println(io, "                description  = ", repr(r.description), ",")
                println(io, "                objective    = ", repr(r.objective), ",")
                println(io, "                targets      = ", repr(r.targets), ",")
                println(io, "                derived_from = ", repr(r.derived_from), ",")
                println(io, "            ),")
            end
            println(io, "        ],")
            println(io, "        [")
            for s in sys.status
                println(io, "            StatusRecord(",
                        repr(s.req_id), ", ", repr(s.target), ", ",
                        s.state, ", ", repr(s.note), "),")
            end
            println(io, "        ],")
            println(io, "    )")
            println(io, "end")
        end
    end
    return dir
end