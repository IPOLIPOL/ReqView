# Run with:  julia --project=. scripts/demo.jl
using DataFrames

include(joinpath(@__DIR__, "..", "src", "ReqView.jl"))
using .ReqView

const DATA = joinpath(@__DIR__, "..", "data")

reg = build_registry(DATA)

println("== Systems ==")
for id in sort!(collect(keys(reg.systems)))
    s = reg.systems[id]
    println("  ", rpad(id, 10), " ", s.name)
end

println("\n== Requirements (", length(reg.requirements), ") ==")
for id in sort!(collect(keys(reg.requirements)))
    r = reg.requirements[id]
    println("  ", rpad(id, 16), " [", rpad(r.origin, 9), "]  targets=", r.targets,
            "  parents=", r.derived_from)
end

println("\n== INCOMING for HVAC ==")
display(DataFrame(incoming_view(reg, "HVAC")))

println("\n== OUTGOING for HVAC ==")
display(DataFrame(outgoing_view(reg, "HVAC")))

println("\n== Descendants of EMP-REQ-001 ==")
foreach(println, descendants(reg, "EMP-REQ-001"))

println("\n== Cycles in derivation graph ==")
foreach(println, derivation_cycles(reg))

println("\n== Mutual allocations (circling pairs) ==")
foreach(println, mutual_allocations(reg))

out = joinpath(@__DIR__, "..", "out"); mkpath(out)
to_excel_all(reg, out)
println("\nExcel written to ", out)