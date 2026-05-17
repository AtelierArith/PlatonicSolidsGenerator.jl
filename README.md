# PlatonicSolidsGenerator.jl

PlatonicSolidsGenerator.jl は、Makie.jl で正多面体を可視化し、3D プリンタ向けの STL ファイルとして書き出す Julia パッケージです。

Bambu Lab / Bambu Studio などのスライサーへ読み込む用途を想定し、STL 座標は millimeter として扱います。STL 形式自体には単位情報がないため、`bbox_mm` で指定した数値を mm としてスライサー側で解釈してください。

## Features

- 5 種類の正多面体を生成
  - 正四面体 `:tetrahedron` / `4`
  - 立方体 `:cube` / `6`
  - 正八面体 `:octahedron` / `8`
  - 正十二面体 `:dodecahedron` / `12`
  - 正二十面体 `:icosahedron` / `20`
- Makie.jl による 3D 可視化
- binary STL 書き出し
- `bbox_mm` による最大 bounding box 寸法指定
- `placement=:flat` による 3D プリント向けのベッド配置
- 将来の 3MF 書き出しに向けた `write_mesh` API

## Installation

このリポジトリをローカルパッケージとして使う場合:

```julia
using Pkg
Pkg.develop(path="/path/to/PlatonicSolidsGenerator.jl")
```

このディレクトリで直接試す場合:

```sh
julia --project=.
```

```julia
using PlatonicSolidsGenerator
```

## Quick Start

### STL を書き出す

```julia
using PlatonicSolidsGenerator

write_mesh("cube.stl", :cube; bbox_mm=30.0, placement=:flat)
write_stl("icosahedron.stl", :icosahedron; bbox_mm=40.0, placement=:flat)
```

`placement=:flat` は、ある 1 面を `z=0` の xy 平面に置き、全頂点が `z >= 0` になるように配置します。Bambu Studio などへ読み込む STL にはこの指定が便利です。

### Makie で可視化する

```julia
using GLMakie
using PlatonicSolidsGenerator

fig = visualize_solid(:dodecahedron; bbox_mm=30.0, placement=:flat)
display(fig)
```

Makie の backend は利用側で選んでください。GLMakie, WGLMakie, CairoMakie などをアプリケーション側で読み込んでから `visualize_solid` を使います。

### GeometryBasics.Mesh を得る

```julia
using PlatonicSolidsGenerator

mesh = platonic_solid(20; bbox_mm=25.0)
```

`platonic_solid` は Makie の `mesh!` などで使える `GeometryBasics.Mesh` を返します。

## Placement

`placement` は以下を指定できます。

- `:center`: デフォルト。中心を原点に置きます。数学的な可視化や形状検証向けです。
- `:flat`: ある面を xy 平面、つまり `z=0` に置きます。3D プリント向けです。

例:

```julia
centered = platonic_solid(:tetrahedron; bbox_mm=30.0, placement=:center)
flat = platonic_solid(:tetrahedron; bbox_mm=30.0, placement=:flat)
```

## API

```julia
supported_solids()
platonic_solid(kind; bbox_mm=30.0, placement=:center)
visualize_solid(kind; bbox_mm=30.0, placement=:center, axis=true)
write_stl(path, kind; bbox_mm=30.0, placement=:center, name=nothing)
write_mesh(path, kind; bbox_mm=30.0, placement=:center, format=:auto, metadata=Dict())
```

`kind` は symbol または面数で指定できます。

```julia
platonic_solid(:cube)
platonic_solid(6)
write_mesh("solid.stl", 12; bbox_mm=50.0, placement=:flat)
```

## 3MF Support

`.3mf` は現時点では未実装です。

ただし `write_mesh(path, kind; format=:auto)` は `.3mf` 拡張子を将来対応予定の形式として認識し、現在は明示的な未対応エラーを返します。今後、同じ内部 mesh 表現から core 3MF writer を追加できる設計にしています。

## Example

5 種類の STL を `exports/` に生成します。

```sh
julia --project=. examples/generate_solids.jl
```

生成されるファイル:

```text
exports/tetrahedron.stl
exports/cube.stl
exports/octahedron.stl
exports/dodecahedron.stl
exports/icosahedron.stl
```

## Testing

```sh
julia --project=. -e 'using Pkg; Pkg.test()'
```

テストでは以下を確認しています。

- 対応する正多面体の一覧
- symbol 指定と面数指定の対応
- `bbox_mm` によるスケーリング
- `placement=:flat` で底面が `z=0` に置かれること
- binary STL の三角形数とファイルサイズ
- `.3mf` が明示的な未対応エラーを返すこと
- Makie 可視化の smoke test
# PlatonicSolidsGenerator.jl
