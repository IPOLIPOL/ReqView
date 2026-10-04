function scada() :: SystemFile
    SystemFile(
        "SCADA",
        "SCADA System",
        [
            Requirement(
                id           = "SCADA-REQ-001",
                origin       = "SCADA",
                name         = "Handle all operational signals in and out with HVAC system",
                description  = "ACMS shall handle all operational signals exchanged with the HVAC system.",
                objective    = "Provide a single operational signal interface between ACMS and HVAC.",
                targets      = ["ACMS"],
                derived_from = ["EMP-REQ-001"],
            ),
            Requirement(
                id           = "SCADA-REQ-002",
                origin       = "SCADA",
                name         = "Provide Ethernet access to HVAC system for diagnostic and engineering tasks",
                description  = "OT LAN shall provide Ethernet access to the HVAC system for diagnostics and engineering.",
                objective    = "Enable remote diagnostics and engineering of HVAC over the OT LAN.",
                targets      = ["OTLAN"],
                derived_from = ["EMP-REQ-001"],
            ),
        ],
        [
            StatusRecord("EMP-REQ-001", "SCADA", IN_PROGRESS, "signal architecture drafted"),
        ],
    )
end