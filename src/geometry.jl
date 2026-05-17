using GeometryBasics

const SOLID_KIND_BY_FACE_COUNT = Dict(
    4 => :tetrahedron,
    6 => :cube,
    8 => :octahedron,
    12 => :dodecahedron,
    20 => :icosahedron,
)

const SUPPORTED_SOLIDS = (:tetrahedron, :cube, :octahedron, :dodecahedron, :icosahedron)

struct SolidMesh
    name::Symbol
    vertices::Vector{NTuple{3,Float64}}
    triangles::Vector{NTuple{3,Int}}
    bbox_mm::Float64
    units::Symbol
    metadata::Dict{Symbol,Any}
end

"""
    supported_solids()

Return the supported Platonic solids as symbols.
"""
supported_solids() = SUPPORTED_SOLIDS

resolve_solid_kind(kind::Integer) =
    get(SOLID_KIND_BY_FACE_COUNT, kind) do
        throw(
            ArgumentError(
                "unsupported solid face count $(repr(kind)); supported face counts are $(sort(collect(keys(SOLID_KIND_BY_FACE_COUNT))))",
            ),
        )
    end

function resolve_solid_kind(kind::Symbol)
    kind in SUPPORTED_SOLIDS && return kind
    throw(
        ArgumentError(
            "unsupported solid identifier $(repr(kind)); supported values are $(SUPPORTED_SOLIDS)",
        ),
    )
end

function resolve_solid_kind(kind)
    throw(
        ArgumentError(
            "unsupported solid identifier $(repr(kind)); pass a supported symbol or face count",
        ),
    )
end

function _validate_bbox_mm(bbox_mm)
    value = Float64(bbox_mm)
    isfinite(value) && value > 0 ||
        throw(ArgumentError("bbox_mm must be positive and finite, got $(repr(bbox_mm))"))
    return value
end

_sub(a, b) = (a[1] - b[1], a[2] - b[2], a[3] - b[3])
_add(a, b) = (a[1] + b[1], a[2] + b[2], a[3] + b[3])
_mul(a, s) = (a[1] * s, a[2] * s, a[3] * s)
_cross(a, b) =
    (a[2] * b[3] - a[3] * b[2], a[3] * b[1] - a[1] * b[3], a[1] * b[2] - a[2] * b[1])
_dot(a, b) = a[1] * b[1] + a[2] * b[2] + a[3] * b[3]
_norm(a) = sqrt(_dot(a, a))
_normalize(a) = _mul(a, 1 / _norm(a))

function _scale_to_bbox(vertices, bbox_mm)
    xs = getindex.(vertices, 1)
    ys = getindex.(vertices, 2)
    zs = getindex.(vertices, 3)
    center = (
        (maximum(xs) + minimum(xs)) / 2,
        (maximum(ys) + minimum(ys)) / 2,
        (maximum(zs) + minimum(zs)) / 2,
    )
    spans =
        (maximum(xs) - minimum(xs), maximum(ys) - minimum(ys), maximum(zs) - minimum(zs))
    scale = bbox_mm / maximum(spans)
    return [
        (
            (v[1] - center[1]) * scale,
            (v[2] - center[2]) * scale,
            (v[3] - center[3]) * scale,
        ) for v in vertices
    ]
end

function _rotate_vector(v, axis, cosθ, sinθ)
    return _add(
        _add(_mul(v, cosθ), _mul(_cross(axis, v), sinθ)),
        _mul(axis, _dot(axis, v) * (1 - cosθ)),
    )
end

function _rotation_axis_for_opposite(normal)
    candidate = abs(normal[1]) < 0.9 ? (1.0, 0.0, 0.0) : (0.0, 1.0, 0.0)
    return _normalize(_cross(normal, candidate))
end

function _rotate_normal_to(vertices, normal, target)
    from = _normalize(normal)
    to = _normalize(target)
    cosθ = clamp(_dot(from, to), -1.0, 1.0)
    if isapprox(cosθ, 1.0; atol = 1e-12)
        return vertices
    end

    axis_cross = _cross(from, to)
    sinθ = _norm(axis_cross)
    axis = sinθ <= 1e-12 ? _rotation_axis_for_opposite(from) : _mul(axis_cross, 1 / sinθ)
    sinθ = sinθ <= 1e-12 ? 0.0 : sinθ

    return [_rotate_vector(v, axis, cosθ, sinθ) for v in vertices]
end

_triangulate(face::NTuple{3,Int}) = [face]
_triangulate(face::NTuple{4,Int}) =
    [(face[1], face[2], face[3]), (face[1], face[3], face[4])]
_triangulate(face::NTuple{5,Int}) =
    [(face[1], face[2], face[3]), (face[1], face[3], face[4]), (face[1], face[4], face[5])]

function _raw_faces(::Val{:tetrahedron})
    vertices = [(-1.0, -1.0, -1.0), (1.0, 1.0, -1.0), (1.0, -1.0, 1.0), (-1.0, 1.0, 1.0)]
    faces = [(1, 3, 2), (1, 2, 4), (1, 4, 3), (2, 3, 4)]
    return vertices, faces
end

function _raw_faces(::Val{:cube})
    vertices = [
        (-1.0, -1.0, -1.0),
        (1.0, -1.0, -1.0),
        (1.0, 1.0, -1.0),
        (-1.0, 1.0, -1.0),
        (-1.0, -1.0, 1.0),
        (1.0, -1.0, 1.0),
        (1.0, 1.0, 1.0),
        (-1.0, 1.0, 1.0),
    ]
    faces =
        [(1, 4, 3, 2), (5, 6, 7, 8), (1, 2, 6, 5), (2, 3, 7, 6), (3, 4, 8, 7), (4, 1, 5, 8)]
    return vertices, faces
end

function _raw_faces(::Val{:octahedron})
    vertices = [
        (1.0, 0.0, 0.0),
        (-1.0, 0.0, 0.0),
        (0.0, 1.0, 0.0),
        (0.0, -1.0, 0.0),
        (0.0, 0.0, 1.0),
        (0.0, 0.0, -1.0),
    ]
    faces = [
        (1, 3, 5),
        (3, 2, 5),
        (2, 4, 5),
        (4, 1, 5),
        (3, 1, 6),
        (2, 3, 6),
        (4, 2, 6),
        (1, 4, 6),
    ]
    return vertices, faces
end

function _raw_faces(::Val{:icosahedron})
    φ = (1 + sqrt(5.0)) / 2
    vertices = [
        (-1.0, φ, 0.0),
        (1.0, φ, 0.0),
        (-1.0, -φ, 0.0),
        (1.0, -φ, 0.0),
        (0.0, -1.0, φ),
        (0.0, 1.0, φ),
        (0.0, -1.0, -φ),
        (0.0, 1.0, -φ),
        (φ, 0.0, -1.0),
        (φ, 0.0, 1.0),
        (-φ, 0.0, -1.0),
        (-φ, 0.0, 1.0),
    ]
    faces = [
        (1, 12, 6),
        (1, 6, 2),
        (1, 2, 8),
        (1, 8, 11),
        (1, 11, 12),
        (2, 6, 10),
        (6, 12, 5),
        (12, 11, 3),
        (11, 8, 7),
        (8, 2, 9),
        (4, 10, 5),
        (4, 5, 3),
        (4, 3, 7),
        (4, 7, 9),
        (4, 9, 10),
        (5, 10, 6),
        (3, 5, 12),
        (7, 3, 11),
        (9, 7, 8),
        (10, 9, 2),
    ]
    return vertices, faces
end

function _raw_faces(::Val{:dodecahedron})
    φ = (1 + sqrt(5.0)) / 2
    vertices = [
        (-1.0, -1.0, -1.0),
        (-1.0, -1.0, 1.0),
        (-1.0, 1.0, -1.0),
        (-1.0, 1.0, 1.0),
        (1.0, -1.0, -1.0),
        (1.0, -1.0, 1.0),
        (1.0, 1.0, -1.0),
        (1.0, 1.0, 1.0),
        (0.0, -1 / φ, -φ),
        (0.0, -1 / φ, φ),
        (0.0, 1 / φ, -φ),
        (0.0, 1 / φ, φ),
        (-1 / φ, -φ, 0.0),
        (-1 / φ, φ, 0.0),
        (1 / φ, -φ, 0.0),
        (1 / φ, φ, 0.0),
        (-φ, 0.0, -1 / φ),
        (φ, 0.0, -1 / φ),
        (-φ, 0.0, 1 / φ),
        (φ, 0.0, 1 / φ),
    ]
    faces = [
        (1, 9, 11, 3, 17),
        (1, 13, 15, 5, 9),
        (1, 17, 19, 2, 13),
        (2, 10, 12, 4, 19),
        (2, 13, 15, 6, 10),
        (3, 11, 7, 16, 14),
        (3, 14, 4, 19, 17),
        (4, 12, 8, 16, 14),
        (5, 18, 7, 11, 9),
        (5, 15, 6, 20, 18),
        (6, 10, 12, 8, 20),
        (7, 18, 20, 8, 16),
    ]
    return vertices, faces
end

function _outward_triangles(vertices, triangles)
    fixed = NTuple{3,Int}[]
    for tri in triangles
        a, b, c = vertices[tri[1]], vertices[tri[2]], vertices[tri[3]]
        normal = _cross(_sub(b, a), _sub(c, a))
        centroid =
            ((a[1] + b[1] + c[1]) / 3, (a[2] + b[2] + c[2]) / 3, (a[3] + b[3] + c[3]) / 3)
        push!(fixed, _dot(normal, centroid) < 0 ? (tri[1], tri[3], tri[2]) : tri)
    end
    return fixed
end

function _face_outward_normal(vertices, face)
    a, b, c = vertices[face[1]], vertices[face[2]], vertices[face[3]]
    normal = _cross(_sub(b, a), _sub(c, a))
    centroid = (
        sum(vertices[i][1] for i in face) / length(face),
        sum(vertices[i][2] for i in face) / length(face),
        sum(vertices[i][3] for i in face) / length(face),
    )
    return _dot(normal, centroid) < 0 ? _mul(normal, -1) : normal
end

function _translate_min_z_to_zero(vertices)
    min_z = minimum(getindex.(vertices, 3))
    return [(v[1], v[2], v[3] - min_z) for v in vertices]
end

function _validate_placement(placement::Symbol)
    placement in (:center, :flat) && return placement
    throw(
        ArgumentError(
            "unsupported placement $(repr(placement)); supported values are :center and :flat",
        ),
    )
end

_validate_placement(placement) = throw(
    ArgumentError(
        "unsupported placement $(repr(placement)); supported values are :center and :flat",
    ),
)

function _place_vertices(vertices, faces, bbox, ::Val{:center})
    return _scale_to_bbox(vertices, bbox)
end

function _place_vertices(vertices, faces, bbox, ::Val{:flat})
    normal = _face_outward_normal(vertices, first(faces))
    rotated = _rotate_normal_to(vertices, normal, (0.0, 0.0, -1.0))
    scaled = _scale_to_bbox(rotated, bbox)
    return _translate_min_z_to_zero(scaled)
end

function _metadata_dict(metadata)
    out = Dict{Symbol,Any}()
    for (key, value) in pairs(metadata)
        out[Symbol(key)] = value
    end
    return out
end

function solid_mesh(
    kind;
    bbox_mm = 30.0,
    placement = :center,
    metadata = Dict{Symbol,Any}(),
)
    name = resolve_solid_kind(kind)
    bbox = _validate_bbox_mm(bbox_mm)
    where = _validate_placement(placement)
    vertices, faces = _raw_faces(Val(name))
    placed = _place_vertices(vertices, faces, bbox, Val(where))
    triangles = NTuple{3,Int}[]
    for face in faces
        append!(triangles, _triangulate(face))
    end
    return SolidMesh(
        name,
        placed,
        _outward_triangles(placed, triangles),
        bbox,
        :mm,
        _metadata_dict(metadata),
    )
end

"""
    platonic_solid(kind; bbox_mm=30.0, placement=:center)

Create a `GeometryBasics.Mesh` for a Platonic solid scaled so its maximum
bounding-box dimension is `bbox_mm`.
"""
function platonic_solid(kind; bbox_mm = 30.0, placement = :center)
    solid = solid_mesh(kind; bbox_mm, placement)
    points = [Point3f(v) for v in solid.vertices]
    faces = [TriangleFace{Int}(tri...) for tri in solid.triangles]
    return GeometryBasics.Mesh(points, faces)
end
