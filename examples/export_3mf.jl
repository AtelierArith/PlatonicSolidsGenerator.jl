using PlatonicSolidsGenerator

mkpath("exports")

# 全ての正多面体を 3MF 形式で export
for kind in supported_solids()
    path = joinpath("exports", string(kind, ".3mf"))
    write_mesh(path, kind; bbox_mm = 30.0, placement = :flat)
    println("Written: $path")
end
