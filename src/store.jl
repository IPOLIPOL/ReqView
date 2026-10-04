# Construction and mutation primitives. All invariants live here.

function add_system!(reg::Registry, id::AbstractString, name::AbstractString)
    id = String(id); name = String(name)
    haskey(reg.systems, id) &&
        throw(ArgumentError("system already registered: $id"))
    reg.systems[id] = SystemFile(id, name, Requirement[], StatusRecord[])
    return reg
end

function add_requirement!(reg::Registry, sys_id::AbstractString, r::Requirement)
    sys_id = String(sys_id)
    sys = get(reg.systems, sys_id, nothing)
    sys === nothing && throw(ArgumentError("unknown system: $sys_id"))
    r.origin == sys_id ||
        throw(ArgumentError("requirement $(r.id) origin=$(r.origin) ≠ system $sys_id"))
    push!(sys.outgoing, r)
    return reg
end

add_requirement!(reg::Registry, sys_id::AbstractString; kwargs...) =
    add_requirement!(reg, sys_id, Requirement(; kwargs...))

function add_status!(reg::Registry, sys_id::AbstractString, s::StatusRecord)
    sys_id = String(sys_id)
    sys = get(reg.systems, sys_id, nothing)
    sys === nothing && throw(ArgumentError("unknown system: $sys_id"))
    s.target == sys_id ||
        throw(ArgumentError("status target=$(s.target) must equal system $sys_id"))
    push!(sys.status, s)
    return reg
end

"""
    set_status!(reg, req_id, target, state, note="")

The only allowed mutation of a live Registry. `target` must be a system that
the requirement is allocated to. The caller is understood to be the target
system — the owner of a requirement may read but not write its status.
"""
function set_status!(reg::Registry, req_id::AbstractString,
                     target::AbstractString, state::Status,
                     note::AbstractString="")
    req_id = String(req_id); target = String(target)
    haskey(reg.systems, target) ||
        throw(ArgumentError("unknown system: $target"))
    r = get(reg.requirements, req_id, nothing)
    r === nothing && throw(ArgumentError("unknown requirement: $req_id"))
    target in r.targets ||
        throw(ArgumentError("requirement $req_id is not allocated to $target"))
    reg.status[(req_id, target)] = StatusRecord(req_id, target, state, String(note))
    return reg
end

"""
    allocations(reg)

The derived allocation relation: (req_id, target) for every target of every
requirement. Computed, never stored — so "allocation ⊆ targets" holds by
construction.
"""
allocations(reg::Registry) =
    [(r.id, t) for r in values(reg.requirements) for t in r.targets]