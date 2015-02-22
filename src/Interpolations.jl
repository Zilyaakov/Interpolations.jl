module Interpolations

export
    interpolate,
    interpolate!,
    extrapolate,

    gradient!,

    OnCell,
    OnGrid,

    Flat,
    Line,
    Free,
    Periodic,
    Reflect,
    Natural,
    InPlace,
    InPlaceQ

    # see the following files for further exports:
    # b-splines/b-splines.jl
    # extrapolation/extrapolation.jl

using WoodburyMatrices, Ratios, AxisAlgorithms

import Base: convert, size, getindex, gradient, promote_rule

abstract InterpolationType
abstract GridType
immutable OnGrid <: GridType end
immutable OnCell <: GridType end

typealias DimSpec{T} Union(T,Tuple{Vararg{T}})

abstract AbstractInterpolation{T,N,IT<:DimSpec{InterpolationType},GT<:DimSpec{GridType}} <: AbstractArray{T,N}
abstract AbstractExtrapolation{T,N,ITPT,IT,GT} <: AbstractInterpolation{T,N,IT,GT}

abstract BoundaryCondition
immutable Flat <: BoundaryCondition end
immutable Line <: BoundaryCondition end
immutable Free <: BoundaryCondition end
immutable Periodic <: BoundaryCondition end
immutable Reflect <: BoundaryCondition end
immutable InPlace <: BoundaryCondition end
# InPlaceQ is exact for an underlying quadratic. This is nice for ground-truth testing
# of in-place (unpadded) interpolation.
immutable InPlaceQ <: BoundaryCondition end
typealias Natural Line

# TODO: size might have to be faster?
size{T,N}(itp::AbstractInterpolation{T,N}) = ntuple(i->size(itp,i), N)::NTuple{N,Int}
size(exp::AbstractExtrapolation, d) = size(exp.itp, d)
gridtype{T,N,IT,GT}(itp::AbstractInterpolation{T,N,IT,GT}) = GT

@inline gradient{T,N}(itp::AbstractInterpolation{T,N}, xs...) = gradient!(Array(T,N), itp, xs...)

include("b-splines/b-splines.jl")
include("gridded/gridded.jl")
include("extrapolation/extrapolation.jl")

nindexes(N::Int) = N == 1 ? "1 index" : "$N indexes"

type FilledInterpolation{T}
    fillvalue
    itp::Interpolation{T}
end
FilledInterpolation(fillvalue, itpargs...) = FilledInterpolation(fillvalue, Interpolation(itpargs...))

function getindex(fitp::FilledInterpolation, args...)
    n = length(args)
    N = ndims(fitp.itp)
    n == N || return error("Must index $(N)-dimensional interpolation objects with $(nindexes(N))")

    for i = 1:length(args)
        if args[i] < 1 || args[i] > size(fitp.itp, i)
            #In the extrapolation region
            return fitp.fillvalue
        end
    end
    #In the interpolation region
    return getindex(fitp.itp,args...)
end

end # module
