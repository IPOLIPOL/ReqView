using Test
include(joinpath(@__DIR__, "..", "src", "ReqView.jl"))
using .ReqView

const DATA = joinpath(@__DIR__, "..", "data")

@testset "ReqView" begin

    @testset "linker: happy path" begin
        reg = build_registry(DATA)
        @test length(reg.systems) == 5
        @test length(reg.requirements) == 10
        @test Set(keys(reg.systems)) ==
              Set(["EMPLOYER", "SCADA", "HVAC", "ACMS", "OTLAN"])
    end

    @testset "allocations follow targets" begin
        reg = build_registry(DATA)
        allocs = Set(allocations(reg))
        for pair in [
            ("EMP-REQ-001", "SCADA"),
            ("EMP-REQ-002", "HVAC"),
            ("SCADA-REQ-001", "ACMS"),
            ("SCADA-REQ-002", "OTLAN"),
            ("HVAC-REQ-001", "ACMS"),
            ("HVAC-REQ-002", "ACMS"),
            ("HVAC-REQ-003", "OTLAN"),
            ("ACMS-REQ-001", "HVAC"),
            ("ACMS-REQ-002", "HVAC"),
            ("OTLAN-REQ-001", "HVAC"),
        ]
            @test pair in allocs
        end
    end

    @testset "derivation is a DAG" begin
        reg = build_registry(DATA)
        @test isempty(derivation_cycles(reg))
    end

    @testset "cascade from EMP-REQ-001" begin
        reg = build_registry(DATA)
        d = Set(descendants(reg, "EMP-REQ-001"))
        @test d == Set([
            "EMP-REQ-001",
            "SCADA-REQ-001", "SCADA-REQ-002",
            "ACMS-REQ-001",  "ACMS-REQ-002",
            "OTLAN-REQ-001",
            "HVAC-REQ-002",  "HVAC-REQ-003",
        ])
        @test !("EMP-REQ-002" in d)
        @test !("HVAC-REQ-001" in d)
    end

    @testset "cascade from EMP-REQ-002" begin
        reg = build_registry(DATA)
        d = Set(descendants(reg, "EMP-REQ-002"))
        @test "HVAC-REQ-001" in d
        @test "ACMS-REQ-001" in d
        @test "ACMS-REQ-002" in d
        @test "HVAC-REQ-002" in d
    end

    @testset "ancestors of HVAC-REQ-002" begin
        reg = build_registry(DATA)
        a = Set(ancestors(reg, "HVAC-REQ-002"))
        @test a == Set([
            "HVAC-REQ-002",
            "ACMS-REQ-001", "ACMS-REQ-002",
            "SCADA-REQ-001", "HVAC-REQ-001",
            "EMP-REQ-001", "EMP-REQ-002",
        ])
    end

    @testset "mutual allocations (circling pairs)" begin
        reg = build_registry(DATA)
        pairs = mutual_allocations(reg)
        @test ("ACMS", "HVAC")   in pairs
        @test ("HVAC", "OTLAN")  in pairs
    end

    @testset "INCOMING for HVAC" begin
        reg = build_registry(DATA)
        rows = incoming_view(reg, "HVAC")
        @test Set(r.req_id for r in rows) ==
              Set(["EMP-REQ-002", "ACMS-REQ-001", "ACMS-REQ-002", "OTLAN-REQ-001"])
        st = Dict(r.req_id => r.status for r in rows)
        @test st["ACMS-REQ-001"]  == "implemented"
        @test st["ACMS-REQ-002"]  == "in progress"
        @test st["OTLAN-REQ-001"] == "not started"
        @test st["EMP-REQ-002"]   == "in progress"
    end

    @testset "OUTGOING for HVAC" begin
        reg = build_registry(DATA)
        rows = outgoing_view(reg, "HVAC")
        @test Set(r.req_id for r in rows) ==
              Set(["HVAC-REQ-001", "HVAC-REQ-002", "HVAC-REQ-003"])
    end

    @testset "set_status! respects allocations" begin
        reg = build_registry(DATA)
        set_status!(reg, "ACMS-REQ-002", "HVAC", IMPLEMENTED, "panel wired")
        @test status_of(reg, "ACMS-REQ-002", "HVAC") == IMPLEMENTED
        @test_throws ArgumentError set_status!(reg, "ACMS-REQ-001", "OTLAN",
                                               IMPLEMENTED, "")
        @test_throws ArgumentError set_status!(reg, "NOPE", "HVAC", IMPLEMENTED, "")
    end

    @testset "linker: rejects unknown target" begin
        src = Registry()
        add_system!(src, "A", "A")
        add_requirement!(src, "A"; id = "A-1", origin = "A", name = "x",
                         targets = ["B"])
        fresh = Registry()
        @test_throws LinkError link!(fresh, [src.systems["A"]])
    end

    @testset "linker: rejects duplicate requirement id" begin
        a = SystemFile("A", "A",
            [Requirement(; id = "X-1", origin = "A", name = "n")],
            StatusRecord[])
        b = SystemFile("B", "B",
            [Requirement(; id = "X-1", origin = "B", name = "n")],
            StatusRecord[])
        @test_throws LinkError link!(Registry(), [a, b])
    end

    @testset "linker: rejects status for non-allocation" begin
        s = SystemFile("A", "A",
            Requirement[],
            [StatusRecord("R", "A", IN_PROGRESS, "")])
        @test_throws LinkError link!(Registry(), [s])
    end

    @testset "to_julia round-trips the registry" begin
        reg = build_registry(DATA)
        mktempdir() do tmp
            to_julia(reg, tmp)
            reg2 = build_registry(tmp)
            @test Set(keys(reg2.requirements)) == Set(keys(reg.requirements))
            @test Set(keys(reg2.systems))      == Set(keys(reg.systems))
            @test Set(allocations(reg2))       == Set(allocations(reg))
            @test Set(keys(reg2.status))       == Set(keys(reg.status))
        end
    end

    @testset "viz smoke" begin
    reg = build_registry(DATA)
    mktempdir() do tmp
        for fn in (plot_derivation, plot_allocations, plot_circulation)
            p = fn(reg; path=joinpath(tmp, string(fn) * ".png"))
            @test isfile(p)
            @test filesize(p) > 1000      # not an empty canvas
        end
    end
end
end