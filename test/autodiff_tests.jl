import FiniteDiff
import ForwardDiff
import ReverseDiff
import Zygote

using Test

F(a, x) = sum(abs2, a) * x^3
F_idx_val(ca) = F(ca[Val(:a)], ca[Val(:x)])
F_idx_sym(ca) = F(ca[:a], ca[:x])
F_view_val(ca) = F(@view(ca[Val(:a)]), ca[Val(:x)])
F_view_sym(ca) = F(@view(ca[:a]), ca[:x])
F_prop(ca) = F(ca.a, ca.x)

ca = ComponentArray(a=[2, 3], x=2.0)
truth = ComponentArray(a = [32, 48], x = 156)

@testset "$(nameof(F_))" for F_ in (F_idx_val, F_idx_sym, F_view_val, F_view_sym, F_prop)
    finite = FiniteDiff.finite_difference_gradient(ca -> F_(ca), ca)
    @test finite ≈ truth

    forward = ForwardDiff.gradient(ca -> F_(ca), ca)
    @test forward ≈ truth

    reverse = ReverseDiff.gradient(ca -> F_(ca), ca)
    @test reverse ≈ truth

    zygote_full = Zygote.gradient(ca -> F_(ca), ca)[1]
    if F_ == F_prop && VERSION < v"1.3"
        @test_broken zygote_full ≈ truth
    else
        @test zygote_full ≈ truth
    end

    # Not sure why this doesn't work in v1.2, but I don't want to drop the tests for that just
    # for this to work
    if VERSION ≥ v"1.6"
        @test ComponentArray(x=4,) == Zygote.gradient(ComponentArray(x=2,)) do c
            (;c...,).x^2
        end[1]
    else
        @test_skip ComponentArray(x=4,) == Zygote.gradient(ComponentArray(x=2,)) do c
            (;c...,).x^2
        end[1]
    end
end


# # This is commented out because the gradient operation itself is broken due to Zygote's inability
# # to support mutation and ComponentArray's use of mutation for contstuction from a NamedTuple.
# # It would be nice to support this eventually, so I'll just leave this commented (because @test_broken
# # wouldn't work here because the error happens before the test)
# @testset "Issues" begin
#     function mysum(x::AbstractVector)
#         y = ComponentVector(x=x)
#         return sum(y)
#     end

#     Δ = Zygote.gradient(mysum, rand(10))

#     @test Δ isa Vector{Float64}
# end
