using Documenter, ResultTypes

makedocs(;
    modules=[ResultTypes],
    format=:html,
    pages=[
        "Home" => "index.md",
        "API" => "pages/api.md",
    ],
    repo="https://github.com/iamed2/ResultTypes.jl/blob/{commit}{path}#L{line}",
    sitename="ResultTypes.jl",
    authors="Eric Davies",
    assets=[],
)

deploydocs(;
    repo="github.com/iamed2/ResultTypes.jl",
    target="build",
    julia="0.6",
    deps=nothing,
    make=nothing,
)
