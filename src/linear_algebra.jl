## https://github.com/SciML/DifferentialEquations.jl/issues/849
function ArrayInterfaceCore.lu_instance(x::ComponentMatrix)
    T = eltype(x)
    noUnitT = typeof(zero(T))
    luT = LinearAlgebra.lutype(noUnitT)
    ipiv = Vector{LinearAlgebra.BlasInt}(undef, 0)
    info = zero(LinearAlgebra.BlasInt)
    return LU{luT}(similar(x), ipiv, info)
end

# Helpers for dealing with adjoints and such
_first_axis(x::AbstractComponentVecOrMat) = getaxes(x)[1]

_second_axis(x::AbstractMatrix) = FlatAxis()
_second_axis(x::ComponentMatrix) = getaxes(x)[2]
_second_axis(x::AdjOrTransComponentVecOrMat) = getaxes(x)[2]

_out_axes(::typeof(*), a, b::AbstractVector) = (_first_axis(a), )
_out_axes(::typeof(*), a, b::AbstractMatrix) = (_first_axis(a), _second_axis(b))
_out_axes(::typeof(\), a, b::AbstractVector) = (_second_axis(a), )
_out_axes(::typeof(\), a, b::AbstractMatrix) = (_second_axis(a), _second_axis(b))
_out_axes(::typeof(/), a::AbstractMatrix, b) = (_first_axis(a), _first_axis(b))

# Arithmetic
for op in [:*, :\, :/]
    @eval begin
        function Base.$op(A::AbstractComponentVecOrMat, B::AbstractComponentVecOrMat)
            C = $op(getdata(A), getdata(B))
            ax = _out_axes($op, A, B)
            return ComponentArray(C, ax)
        end
    end
    for (adj, Adj) in zip([:adjoint, :transpose], [:Adjoint, :Transpose])
        @eval begin
            function Base.$op(aᵀ::$Adj{T,<:ComponentVector}, B::AbstractComponentMatrix) where {T}
                cᵀ = $op(getdata(aᵀ), getdata(B))
                ax2 = _out_axes($op, aᵀ, B)[2]
                return $adj(ComponentArray(cᵀ', ax2))
            end
            function Base.$op(A::$Adj{T,<:CV}, B::CV) where {T<:Real, CV<:ComponentVector{T}}
                return $op(getdata(A), getdata(B))
            end
        end
    end
end