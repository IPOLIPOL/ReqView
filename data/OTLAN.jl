function otlan() :: SystemFile
    SystemFile(
        "OTLAN",
        "OT LAN",
        [
            Requirement(
                id           = "OTLAN-REQ-001",
                origin       = "OTLAN",
                name         = "Provide network physical connection point in HVAC control cabinet",
                description  = "HVAC shall provide the physical network connection point inside its control cabinet.",
                objective    = "Provide a landing point for OT LAN cabling at the HVAC cabinet.",
                targets      = ["HVAC"],
                derived_from = ["SCADA-REQ-002"],
            ),
        ],
        [
            StatusRecord("SCADA-REQ-002", "OTLAN", NOT_STARTED, ""),
            StatusRecord("HVAC-REQ-003",  "OTLAN", NOT_STARTED, ""),
        ],
    )
end