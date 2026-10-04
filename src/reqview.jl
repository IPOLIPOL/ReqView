module ReqView

using Graphs
using Tables
using DataFrames
using XLSX

export Status, NOT_STARTED, IN_PROGRESS, IMPLEMENTED
export Requirement, StatusRecord, SystemFile, Registry, LinkError
export add_system!, add_requirement!, add_status!, set_status!, allocations
export link!, load_data, build_registry, to_julia
export incoming_view, outgoing_view, status_of
export derivation_graph, allocation_graph
export descendants, ancestors, derivation_cycles, mutual_allocations
export to_excel, to_excel_all, status_label, parse_status
export system_colors, plot_derivation, plot_allocations, plot_circulation

include("types.jl")
include("store.jl")
include("linker.jl")
include("views.jl")
include("graph.jl")
include("excel.jl")
include("viz.jl")

end # module


