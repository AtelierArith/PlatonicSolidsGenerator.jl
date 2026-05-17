using PlatonicSolidsGenerator

mkpath("exports")

for kind in supported_solids()
    write_mesh(
        joinpath("exports", string(kind, ".stl")),
        kind;
        bbox_mm = 30.0,
        placement = :flat,
    )
end

fig = visualize_solid(:icosahedron; bbox_mm = 30.0, placement = :flat)
fig
