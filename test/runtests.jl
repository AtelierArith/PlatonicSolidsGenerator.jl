using Test
using PlatonicSolidsGenerator

@testset "supported solids" begin
    @test supported_solids() ==
          (:tetrahedron, :cube, :octahedron, :dodecahedron, :icosahedron)

    @test PlatonicSolidsGenerator.resolve_solid_kind(4) == :tetrahedron
    @test PlatonicSolidsGenerator.resolve_solid_kind(6) == :cube
    @test PlatonicSolidsGenerator.resolve_solid_kind(8) == :octahedron
    @test PlatonicSolidsGenerator.resolve_solid_kind(12) == :dodecahedron
    @test PlatonicSolidsGenerator.resolve_solid_kind(20) == :icosahedron
    @test PlatonicSolidsGenerator.resolve_solid_kind(:cube) == :cube

    @test_throws ArgumentError PlatonicSolidsGenerator.resolve_solid_kind(10)
    @test_throws ArgumentError platonic_solid(:bad)
    @test_throws ArgumentError platonic_solid(:cube; bbox_mm = 0)
end

@testset "geometry scaling and triangles" begin
    expected_triangles = Dict(
        :tetrahedron => 4,
        :cube => 12,
        :octahedron => 8,
        :dodecahedron => 36,
        :icosahedron => 20,
    )

    for kind in supported_solids()
        solid = PlatonicSolidsGenerator.solid_mesh(kind; bbox_mm = 42.0)
        @test solid.name == kind
        @test solid.units == :mm
        @test length(solid.triangles) == expected_triangles[kind]

        xs = getindex.(solid.vertices, 1)
        ys = getindex.(solid.vertices, 2)
        zs = getindex.(solid.vertices, 3)
        spans = (
            maximum(xs) - minimum(xs),
            maximum(ys) - minimum(ys),
            maximum(zs) - minimum(zs),
        )
        @test maximum(spans) ≈ 42.0 atol = 1e-8
        @test (maximum(xs) + minimum(xs)) / 2 ≈ 0 atol = 1e-8
        @test (maximum(ys) + minimum(ys)) / 2 ≈ 0 atol = 1e-8
        @test (maximum(zs) + minimum(zs)) / 2 ≈ 0 atol = 1e-8
    end

    @test PlatonicSolidsGenerator.solid_mesh(6; bbox_mm = 10).name == :cube
end

@testset "flat placement" begin
    for kind in supported_solids()
        solid = PlatonicSolidsGenerator.solid_mesh(kind; bbox_mm = 42.0, placement = :flat)
        zs = getindex.(solid.vertices, 3)

        @test minimum(zs) ≈ 0 atol = 1e-8
        @test all(z -> z >= -1e-8, zs)
        @test count(z -> isapprox(z, 0; atol = 1e-8), zs) >= 3

        xs = getindex.(solid.vertices, 1)
        ys = getindex.(solid.vertices, 2)
        spans = (
            maximum(xs) - minimum(xs),
            maximum(ys) - minimum(ys),
            maximum(zs) - minimum(zs),
        )
        @test maximum(spans) ≈ 42.0 atol = 1e-8
    end

    @test_throws ArgumentError PlatonicSolidsGenerator.solid_mesh(
        :cube;
        placement = :sideways,
    )
end

@testset "binary STL export" begin
    mktempdir() do dir
        counts = Dict(
            :tetrahedron => 4,
            :cube => 12,
            :octahedron => 8,
            :dodecahedron => 36,
            :icosahedron => 20,
        )
        for (kind, count) in counts
            path = joinpath(dir, string(kind, ".stl"))
            @test write_stl(path, kind; bbox_mm = 25.0) == path
            @test filesize(path) == 84 + 50 * count
            open(path, "r") do io
                seek(io, 80)
                @test read(io, UInt32) == count
            end
        end

        auto_path = joinpath(dir, "auto.stl")
        @test write_mesh(auto_path, 6; bbox_mm = 12.0) == auto_path
        @test filesize(auto_path) == 84 + 50 * 12

        flat_path = joinpath(dir, "flat.stl")
        @test write_mesh(flat_path, :tetrahedron; bbox_mm = 12.0, placement = :flat) ==
              flat_path
        @test filesize(flat_path) == 84 + 50 * 4

        err = try
            write_mesh(joinpath(dir, "future.3mf"), :cube)
            nothing
        catch e
            e
        end
        @test err isa ErrorException
        @test occursin("3MF export is not implemented yet", sprint(showerror, err))

        @test_throws ArgumentError write_mesh(joinpath(dir, "mesh.obj"), :cube)
    end
end

@testset "Makie visualization" begin
    fig = visualize_solid(:cube; bbox_mm = 20.0)
    @test Base.typename(typeof(fig)).name == :Figure

    flat_fig = visualize_solid(:cube; bbox_mm = 20.0, placement = :flat)
    @test Base.typename(typeof(flat_fig)).name == :Figure
end
