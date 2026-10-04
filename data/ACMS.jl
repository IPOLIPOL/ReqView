function acms() :: SystemFile
    SystemFile(
        "ACMS",
        "ACMS",
        [
            Requirement(
                id           = "ACMS-REQ-001",
                origin       = "ACMS",
                name         = "Provide RIO module ET200 in the control cabinet per specification NNN",
                description  = "HVAC shall mount a RIO module ET200 in its control cabinet per specification NNN.",
                objective    = "Provide the field I/O backbone for local and remote operation.",
                targets      = ["HVAC"],
                derived_from = ["SCADA-REQ-001", "HVAC-REQ-001"],
            ),
            Requirement(
                id           = "ACMS-REQ-002",
                origin       = "ACMS",
                name         = "Provide local HMI panel in the control cabinet",
                description  = "HVAC shall install a local HMI panel in its control cabinet.",
                objective    = "Provide a local operator interface at the HVAC cabinet.",
                targets      = ["HVAC"],
                derived_from = ["SCADA-REQ-001", "HVAC-REQ-001"],
            ),
        ],
        [
            StatusRecord("SCADA-REQ-001", "ACMS", IN_PROGRESS, "IO list under review"),
            StatusRecord("HVAC-REQ-001",  "ACMS", IN_PROGRESS, "HMI concept drafted"),
            StatusRecord("HVAC-REQ-002",  "ACMS", NOT_STARTED, ""),
        ],
    )
end