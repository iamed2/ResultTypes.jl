var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Home",
    "title": "Home",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#ResultTypes-1",
    "page": "Home",
    "title": "ResultTypes",
    "category": "section",
    "text": "(Image: Build Status) (Image: codecov)ResultTypes provides a Result type which can hold either a value or an error. This allows us to return a value or an error in a type-stable manner without throwing an exception.DocTestSetup = quote\n    using ResultTypes\nend"
},

{
    "location": "index.html#Usage-1",
    "page": "Home",
    "title": "Usage",
    "category": "section",
    "text": ""
},

{
    "location": "index.html#Basic-1",
    "page": "Home",
    "title": "Basic",
    "category": "section",
    "text": "We can construct a Result that holds a value:julia> x = Result(2); typeof(x)\nResultTypes.Result{Int64,Exception}or a Result that holds an error:julia> x = ErrorResult(Int, \"Oh noes!\"); typeof(x)\nResultTypes.Result{Int64,ErrorException}or either with a different error type:julia> x = Result(2, DivideError); typeof(x)\nResultTypes.Result{Int64,DivideError}\n\njulia> x = ErrorResult(Int, DivideError()); typeof(x)\nResultTypes.Result{Int64,DivideError}"
},

{
    "location": "index.html#Exploiting-Function-Return-Types-1",
    "page": "Home",
    "title": "Exploiting Function Return Types",
    "category": "section",
    "text": "We can take advantage of automatic conversions in function returns (a Julia 0.5 feature):julia> function integer_division(x::Int, y::Int)::Result{Int, DivideError}\n           if y == 0\n               return DivideError()\n           else\n               return div(x, y)\n           end\n       end\ninteger_division (generic function with 1 method)This allows us to write code in the body of the function that returns either a value or an error without manually constructing Result types.julia> integer_division(3, 4)\nResult(0)\n\njulia> integer_division(3, 0)\nErrorResult(Int64, DivideError())"
},

{
    "location": "pages/api.html#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "pages/api.html#ResultTypes-API-1",
    "page": "API",
    "title": "ResultTypes API",
    "category": "section",
    "text": ""
},

{
    "location": "pages/api.html#ResultTypes.Result",
    "page": "API",
    "title": "ResultTypes.Result",
    "category": "type",
    "text": "Result(val::T, exception_type::Type{E}=Exception) -> Result{T, E}\n\nCreate a Result that could hold a value of type T or an exception of type E, and store val in it. If the exception type is not provided, the supertype Exception is used as E.\n\n\n\n"
},

{
    "location": "pages/api.html#ResultTypes.ErrorResult",
    "page": "API",
    "title": "ResultTypes.ErrorResult",
    "category": "function",
    "text": "ErrorResult(::Type{T}, exception::E) -> Result{T, E}\nErrorResult(::Type{T}, exception::AbstractString=\"\") -> Result{T, ErrorException}\n\nCreate a Result that could hold a value of type T or an exception of type E, and store exception in it. If the exception is provided as text, it is wrapped in the generic ErrorException. If no exception is provided, an ErrorException with an empty string is used. If the type argument is not provided, Any is used.\n\nErrorResult is a convenience function for creating a Result and is not its own type.\n\n\n\n"
},

{
    "location": "pages/api.html#Constructors-1",
    "page": "API",
    "title": "Constructors",
    "category": "section",
    "text": "Result\nErrorResult"
},

{
    "location": "pages/api.html#ResultTypes.unwrap",
    "page": "API",
    "title": "ResultTypes.unwrap",
    "category": "function",
    "text": "unwrap(result::Result{T, E}) -> T\nunwrap(val::T) -> T\nunwrap(::Type{T}, result_or_val) -> T\n\nAssumes result holds a value of type T and returns it. If result holds an exception instead, that exception is thrown.\n\nIf unwrap\'s argument is not a Result, it is returned.\n\nThe two-argument form of unwrap calls unwrap on its second argument, then converts it to type T.\n\n\n\n"
},

{
    "location": "pages/api.html#ResultTypes.unwrap_error",
    "page": "API",
    "title": "ResultTypes.unwrap_error",
    "category": "function",
    "text": "unwrap_error(result::Result{T, E}) -> E\nunwrap_error(exception::E) -> E\n\nAssumes result holds an exception of type E and returns it. If result holds a value instead, throw an exception.\n\nIf unwrap_error\'s argument is an Exception, that exception is returned.\n\n\n\n"
},

{
    "location": "pages/api.html#ResultTypes.iserror",
    "page": "API",
    "title": "ResultTypes.iserror",
    "category": "function",
    "text": "ResultTypes.iserror(x) -> Bool\n\nIf x is an Exception, return true. If x is an ErrorResult (a Result containing an Exception), return true. Return false in all other cases.\n\n\n\n"
},

{
    "location": "pages/api.html#Functions-1",
    "page": "API",
    "title": "Functions",
    "category": "section",
    "text": "unwrap\nunwrap_error\nResultTypes.iserror"
},

]}
