module PlatonicSolidsGenerator

export supported_solids, platonic_solid, polyhedron_edges, visualize_solid, write_stl, write_mesh

using GeometryBasics: Point3f, TriangleFace, Mesh
import EzXML
import ZipFile
using Makie: Figure, Axis3, mesh!, linesegments!, hidedecorations!

include("geometry.jl")
include("threemf.jl")
include("stl.jl")
include("visualization.jl")

end # module PlatonicSolidsGenerator
