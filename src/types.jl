# Core domain types for the Requirements View.
#
# Architectural commitments (see the Requirements View document):
#   * a requirement has ONE identity and ONE origin/owner;
#   * allocation (projection) to a target system is a separate relation,
#     derived from `targets` and never stored separately;
#   * status belongs to the (requirement, target) projection, not to the
#     requirement, and is owned by the target system;
#   * `derived_from` is explicit and carries the cascade; cycles are allowed.

"""
    Status

Lifecycle state of a single (requirement, target) projection.
"""
@enum Status begin
    NOT_STARTED
    IN_PROGRESS
    IMPLEMENTED
end

status_label(s::Status) = s === NOT_STARTED ? "not started" :
                          s === IN_PROGRESS ? "in progress" :
                                              "implemented"

function parse_status(x::AbstractString)
    s = lowercase(strip(x))
    s == "not started" && return NOT_STARTED
    s == "in progress" && return IN_PROGRESS
    s == "implemented" && return IMPLEMENTED
    throw(ArgumentError("unknown status: $(repr(x))"))
end

"""
    Requirement

`id` is globally unique across all systems.
`origin` is the system that owns and maintains the definition.
`targets` is the allocation list: systems that must consider or implement it.
`derived_from` is the cascade: requirement ids this one was refined from.
"""
struct Requirement
    id           :: String
    origin       :: String
    name         :: String
    description  :: String
    objective    :: String
    targets      :: Vector{String}
    derived_from :: Vector{String}
end

Requirement(; id, origin, name, description="", objective="",
              targets=String[], derived_from=String[]) =
    Requirement(String(id), String(origin), String(name),
                String(description), String(objective),
                String.(targets), String.(derived_from))

"""
    StatusRecord

The response of a target system to a requirement allocated to it.
Keyed by (req_id, target) — i.e. by the projection, not the requirement.
"""
struct StatusRecord
    req_id :: String
    target :: String
    state  :: Status
    note   :: String
end

StatusRecord(req_id::AbstractString, target::AbstractString) =
    StatusRecord(String(req_id), String(target), NOT_STARTED, "")

StatusRecord(; req_id, target, state=NOT_STARTED, note="") =
    StatusRecord(String(req_id), String(target), state, String(note))

"""
    SystemFile

One file per system/actor. Contains that system's outgoing requirements and
its responses to requirements allocated to it.
"""
struct SystemFile
    id       :: String
    name     :: String
    outgoing :: Vector{Requirement}
    status   :: Vector{StatusRecord}
end

"""
    Registry

The single in-memory source of truth, produced by the linker.
Allocations are derived (see `allocations`), never stored.
"""
mutable struct Registry
    systems      :: Dict{String,SystemFile}
    requirements :: Dict{String,Requirement}
    status       :: Dict{Tuple{String,String},StatusRecord}
end

Registry() = Registry(
    Dict{String,SystemFile}(),
    Dict{String,Requirement}(),
    Dict{Tuple{String,String},StatusRecord}(),
)

"""
    LinkError

Raised by the linker when cross-system consistency is violated.
"""
struct LinkError <: Exception
    stage     :: Symbol
    offending :: String
    message   :: String
end

function Base.showerror(io::IO, e::LinkError)
    print(io, "LinkError[", e.stage, "] on ", repr(e.offending), ": ", e.message)
end