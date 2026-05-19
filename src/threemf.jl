using EzXML
using ZipFile

struct ThreeMFMesh
    vertices::Vector{Tuple{Float64,Float64,Float64}}
    triangles::Vector{Tuple{Int,Int,Int}}

    function ThreeMFMesh(vertices, triangles)
        verts = Tuple{Float64,Float64,Float64}[]
        for v in vertices
            t = Tuple(v)
            length(t) == 3 || throw(ArgumentError(
                "each vertex must have exactly 3 components, got $(length(t)): $t"
            ))
            push!(verts, (Float64(t[1]), Float64(t[2]), Float64(t[3])))
        end

        nv = length(verts)
        tris = Tuple{Int,Int,Int}[]
        for tri in triangles
            t = Tuple(tri)
            length(t) == 3 || throw(ArgumentError(
                "each triangle must have exactly 3 indices, got $(length(t)): $t"
            ))
            a, b, c = Int(t[1]), Int(t[2]), Int(t[3])
            for idx in (a, b, c)
                (0 <= idx < nv) || throw(ArgumentError(
                    "triangle index $idx is out of range 0:$(nv-1)"
                ))
            end
            push!(tris, (a, b, c))
        end

        new(verts, tris)
    end
end

const _CONTENT_TYPES_XML = """<?xml version="1.0" encoding="UTF-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="model" ContentType="application/vnd.ms-package.3dmanufacturing-3dmodel+xml"/>
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
</Types>"""

const _RELS_XML = """<?xml version="1.0" encoding="UTF-8"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
</Relationships>"""

const _3MF_CORE_NS = "http://schemas.microsoft.com/3dmanufacturing/core/2015/02"

function _model_xml(mesh::ThreeMFMesh)::String
    doc = EzXML.XMLDocument()
    model = EzXML.ElementNode("model")
    EzXML.setroot!(doc, model)
    model["unit"] = "millimeter"
    model["xmlns"] = _3MF_CORE_NS

    resources = EzXML.addelement!(model, "resources")
    object = EzXML.addelement!(resources, "object")
    object["id"] = "1"
    object["type"] = "model"

    mesh_el = EzXML.addelement!(object, "mesh")

    vertices_el = EzXML.addelement!(mesh_el, "vertices")
    for (x, y, z) in mesh.vertices
        v = EzXML.addelement!(vertices_el, "vertex")
        v["x"] = string(x)
        v["y"] = string(y)
        v["z"] = string(z)
    end

    triangles_el = EzXML.addelement!(mesh_el, "triangles")
    for (v1, v2, v3) in mesh.triangles
        t = EzXML.addelement!(triangles_el, "triangle")
        t["v1"] = string(v1)
        t["v2"] = string(v2)
        t["v3"] = string(v3)
    end

    build = EzXML.addelement!(model, "build")
    item = EzXML.addelement!(build, "item")
    item["objectid"] = "1"

    io = IOBuffer()
    print(io, doc)
    return String(take!(io))
end

function _write_3mf(mesh::ThreeMFMesh, path::AbstractString)
    mkpath(dirname(abspath(path)))
    zf = ZipFile.Writer(path)

    f1 = ZipFile.addfile(zf, "[Content_Types].xml")
    write(f1, _CONTENT_TYPES_XML)

    f2 = ZipFile.addfile(zf, "_rels/.rels")
    write(f2, _RELS_XML)

    f3 = ZipFile.addfile(zf, "3D/3dmodel.model")
    write(f3, _model_xml(mesh))

    close(zf)
    return path
end
