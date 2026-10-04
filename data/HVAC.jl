function hvac() :: SystemFile
    SystemFile(
        "HVAC",
        "HVAC System",
        [
            Requirement(
                id           = "HVAC-REQ-001",
                origin       = "HVAC",
                name         = "Provide local operation functionality",
                description  = "ACMS shall provide the local operation functionality requested by HVAC.",
                objective    = "Fulfil the local manual operation capability of HVAC.",
                targets      = ["ACMS"],
                derived_from = ["EMP-REQ-002"],
            ),
            Requirement(
                id           = "HVAC-REQ-002",
                origin       = "HVAC",
                name         = "Provide programming and configuration of HMI local panel with RIO module",
                description  = "ACMS shall program and configure the HMI local panel together with the RIO module.",
                objective    = "Make the HMI + RIO combination functional for local operation.",
                targets      = ["ACMS"],
                derived_from = ["ACMS-REQ-001", "ACMS-REQ-002"],
            ),
            Requirement(
                id           = "HVAC-REQ-003",
                origin       = "HVAC",
                name         = "Connect the HMI panel to LAN and provide TCP/IP and open ports",
                description  = "OT LAN shall connect the HMI panel to the LAN and provide the required TCP/IP parameters and open ports.",
                objective    = "Make the HMI reachable over the OT LAN for diagnostics and engineering.",
                targets      = ["OTLAN"],
                derived_from = ["OTLAN-REQ-001"],
            ),
        ],
        [
            StatusRecord("EMP-REQ-002",   "HVAC", IN_PROGRESS, "cabinet design in progress"),
            StatusRecord("ACMS-REQ-001",  "HVAC", IMPLEMENTED, "RIO module mounted"),
            StatusRecord("ACMS-REQ-002",  "HVAC", IN_PROGRESS, "HMI panel ordered"),
            StatusRecord("OTLAN-REQ-001", "HVAC", NOT_STARTED, ""),
        ],
    )
end