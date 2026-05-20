"""
    visualize_solid(kind; bbox_mm=30.0, placement=:center, axis=true)

Create a Makie `Figure` containing a 3D rendering of a Platonic solid.
The active Makie backend is selected by the caller's environment.
"""
function visualize_solid(kind; bbox_mm = 30.0, placement = :center, axis = true)
    mesh = platonic_solid(kind; bbox_mm, placement)
    fig = Figure(size = (700, 600))
    ax = Axis3(fig[1, 1]; aspect = (1, 1, 1))
    mesh!(ax, mesh; color = :lightskyblue)
    if !axis
        hidedecorations!(ax)
    end
    return fig
end
