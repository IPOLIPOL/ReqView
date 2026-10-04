# Tabular projections — the Excel-shaped views.
# Each returns Vector{NamedTuple}, which Tables.jl treats as a table, so
# DataFrame / XLSX / CSV sinks work without further code.

"""
    outgoing_view(reg, sys_id)

OUTGOING sheet for `sys_id`:
    targets | req_id | name | description | objective
"""
function outgoing_view(reg::Registry, sys_id::AbstractString)
    sys_id = String(sys_id)
    haskey(reg.systems, sys_id) || throw(ArgumentError("unknown system: $sys_id"))
    rowt = NamedTuple{(:targets, :req_id, :name, :description, :objective),
                      Tuple{String,String,String,String,String}}
    rows = rowt[]
    for r in sort(collect(values(reg.requirements)); by = r -> r.id)
        r.origin == sys_id || continue
        push!(rows, (
            targets     = join(r.targets, "; "),
            req_id      = r.id,
            name        = r.name,
            description = r.description,
            objective   = r.objective,
        ))
    end
    return rows
end

"""
    incoming_view(reg, sys_id)

INCOMING sheet for `sys_id`:
    owner | req_id | name | description | objective | status
"""
function incoming_view(reg::Registry, sys_id::AbstractString)
    sys_id = String(sys_id)
    haskey(reg.systems, sys_id) || throw(ArgumentError("unknown system: $sys_id"))
    rowt = NamedTuple{(:owner, :req_id, :name, :description, :objective, :status),
                      Tuple{String,String,String,String,String,String}}
    rows = rowt[]
    for r in sort(collect(values(reg.requirements)); by = r -> r.id)
        sys_id in r.targets || continue
        st = get(reg.status, (r.id, sys_id), nothing)
        label = st === nothing ? status_label(NOT_STARTED) : status_label(st.state)
        push!(rows, (
            owner       = r.origin,
            req_id      = r.id,
            name        = r.name,
            description = r.description,
            objective   = r.objective,
            status      = label,
        ))
    end
    return rows
end

"""
    status_of(reg, req_id, target) -> Status

Read a projection's status; `NOT_STARTED` if no record exists yet.
"""
function status_of(reg::Registry, req_id::AbstractString, target::AbstractString)
    st = get(reg.status, (String(req_id), String(target)), nothing)
    return st === nothing ? NOT_STARTED : st.state
end