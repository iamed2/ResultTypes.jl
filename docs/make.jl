using Documenter, ResultTypes

makedocs(;
    modules=[ResultTypes],
    format=Documenter.HTML(),
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
)
