function _triangle_normal(a, b, c)
    n = _cross(_sub(b, a), _sub(c, a))
    len = sqrt(_dot(n, n))
    len > 0 || throw(ArgumentError("mesh contains a degenerate triangle"))
    return (n[1] / len, n[2] / len, n[3] / len)
end

function _write_vec3_float32(io, v)
    write(io, Float32(v[1]))
    write(io, Float32(v[2]))
    write(io, Float32(v[3]))
    return nothing
end

"""
    write_stl(path, kind; bbox_mm=30.0, placement=:center, name=nothing)

Write `kind` as a binary STL file scaled in millimeters by `bbox_mm`.
Returns the written path.
"""
function write_stl(path, kind; bbox_mm = 30.0, placement = :center, name = nothing)
    solid = solid_mesh(kind; bbox_mm, placement)
    isempty(solid.triangles) &&
        throw(ArgumentError("cannot write STL for a mesh with no triangles"))
    label = String(name === nothing ? solid.name : name)

    open(path, "w") do io
        header = rpad("PlatonicSolidsGenerator $(label) units=mm", 80)[1:80]
        write(io, codeunits(header))
        write(io, htol(UInt32(length(solid.triangles))))
        for tri in solid.triangles
            a, b, c = solid.vertices[tri[1]], solid.vertices[tri[2]], solid.vertices[tri[3]]
            _write_vec3_float32(io, _triangle_normal(a, b, c))
            _write_vec3_float32(io, a)
            _write_vec3_float32(io, b)
            _write_vec3_float32(io, c)
            write(io, htol(UInt16(0)))
        end
    end

    return path
end

function _infer_format(path, ::Val{:auto})
    ext = lowercase(splitext(String(path))[2])
    ext == ".stl" && return :stl
    ext == ".3mf" && return Symbol("3mf")
    throw(
        ArgumentError(
            "cannot infer mesh format from extension $(repr(ext)); supported extension is .stl and .3mf is reserved for future support",
        ),
    )
end

_infer_format(_path, format::Symbol) = format
_infer_format(_path, format::AbstractString) = Symbol(lowercase(format))
_infer_format(_path, format) = throw(
    ArgumentError(
        "unsupported mesh format selector $(repr(format)); use :auto, :stl, or :3mf",
    ),
)

function _metadata_name(metadata)
    haskey(metadata, :name) && return metadata[:name]
    return nothing
end

"""
    write_mesh(path, kind; bbox_mm=30.0, placement=:center, format=:auto, metadata=Dict())

Write a mesh file, inferring the format from `path` when `format=:auto`.
Currently supports STL. 3MF is recognized as a future extension point and
throws a clear unsupported error.
"""
function write_mesh(
    path,
    kind;
    bbox_mm = 30.0,
    placement = :center,
    format = :auto,
    metadata = Dict{Symbol,Any}(),
)
    resolved =
        format === :auto ? _infer_format(path, Val(:auto)) : _infer_format(path, format)
    if resolved == :stl
        return write_stl(path, kind; bbox_mm, placement, name = _metadata_name(metadata))
    elseif resolved == Symbol("3mf")
        solid = solid_mesh(kind; bbox_mm, placement, metadata)
        tmesh = ThreeMFMesh(
            solid.vertices,
            [(t[1] - 1, t[2] - 1, t[3] - 1) for t in solid.triangles],
        )
        return _write_3mf(tmesh, path)
    end
    throw(
        ArgumentError(
            "unsupported mesh format $(repr(resolved)); supported format is :stl and :3mf is reserved for future support",
        ),
    )
end
