function employer() :: SystemFile
    SystemFile(
        "EMPLOYER",
        "Employer",
        [
            Requirement(
                id           = "EMP-REQ-001",
                origin       = "EMPLOYER",
                name         = "Provide remote operation and access to HVAC system through SCADA",
                description  = "The HVAC system shall be operable and observable remotely via the SCADA layer.",
                objective    = "Enable remote operation and monitoring of HVAC from the central SCADA.",
                targets      = ["SCADA"],
                derived_from = String[],
            ),
            Requirement(
                id           = "EMP-REQ-002",
                origin       = "EMPLOYER",
                name         = "Provide local operation functionality of HVAC system in manual mode",
                description  = "HVAC shall support local manual operation independent of SCADA availability.",
                objective    = "Ensure operability of HVAC when the remote layer is unavailable.",
                targets      = ["HVAC"],
                derived_from = String[],
            ),
        ],
        StatusRecord[],
    )
end