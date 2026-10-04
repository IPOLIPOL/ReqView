# Excel round-trip.
#
# Sheet structure follows the Requirements View document exactly:
#
#   OUTGOING:  targets | req_id | name | description | objective
#   INCOMING:  owner   | req_id | name | description | objective | status
#
# Both views are Vector{NamedTuple}, which is a Tables.jl source, so
# DataFrame construction and XLSX.writetable both consume them directly.

"""
    to_excel(reg, sys_id, path)

Write a single workbook for `sys_id` with two sheets, INCOMING and OUTGOING.
"""
function to_excel(reg::Registry, sys_id::AbstractString, path::AbstractString)
    inc = DataFrame(incoming_view(reg, sys_id))
    out = DataFrame(outgoing_view(reg, sys_id))
    XLSX.writetable(path, ["INCOMING" => inc, "OUTGOING" => out])
    return path
end

"""
    to_excel_all(reg, dir)

Write one workbook per system into `dir`, named `<SYSTEM>.xlsx`.
"""
function to_excel_all(reg::Registry, dir::AbstractString)
    dir = abspath(dir); mkpath(dir)
    for id in sort!(collect(keys(reg.systems)))
        to_excel(reg, id, joinpath(dir, id * ".xlsx"))
    end
    return dir
end