using GLMakie
using PlatonicSolidsGenerator

solids = supported_solids()
colors = [:lightskyblue, :lightcoral, :lightgreen, :lightyellow, :plum]

fig = Figure(size = (1400, 600))
for (i, kind) in enumerate(solids)
    row, col = divrem(i - 1, 3)
    ax = Axis3(
        fig[row + 1, col + 1];
        aspect = (1, 1, 1),
        title = string(kind),
    )
    mesh!(ax, platonic_solid(kind; bbox_mm = 30.0); color = colors[i])
    linesegments!(ax, polyhedron_edges(kind; bbox_mm = 30.0); color = :black, linewidth = 1.5)
    hidedecorations!(ax)
end

screen = display(fig)
wait(screen)
