module PlatonicSolidsGenerator

export supported_solids, platonic_solid, visualize_solid, write_stl, write_mesh

include("geometry.jl")
include("stl.jl")
include("visualization.jl")

end # module PlatonicSolidsGenerator
