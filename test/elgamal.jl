using Test
import CryptoGroups
import CryptoGroups: PGroup, specialize, Enc, Dec, <|, generator, PGroup, ECGroup

function elgamal_test(g)

    sk = 5
    pk = g^sk
    r = 3
    m = g^5
    r2 = 6

    enc = Enc(pk, g)
    dec = Dec(sk)

    @test dec(enc(m, r)) == m
    @test enc(enc(m, r), r2) == enc(m, r + r2)

    ### Shuffle generation

    sk = 5
    pk = g^sk

    enc = Enc(pk, g)

    m_vec = [g^4, g^2, g^3]
    e_vec = enc.(m_vec, [2, 3, 7]) 

    ### The shuffling
    r_vec = Int[4, 2, 3]

    e_enc = enc.(e_vec, r_vec)
    ψ = sortperm(e_enc)
    sort!(e_enc)

    @test sort(dec.(e_enc)) == sort(m_vec)

    #m_vec = [g, g^2, g^3]
    #e_vec = enc.(m_vec, 1)
end


let
    q = 11
    p = 2*q + 1

    G = specialize(PGroup, p, q, :G)
    g = G(3)

    elgamal_test(g)
end


import CryptoGroups
import CryptoGroups: specialize, <|, generator, PGroup, ECGroup


let
    spec = CryptoGroups.MODP_1024
    G = specialize(PGroup, spec)
    g = G <| generator(spec)

    elgamal_test(g)
end


let
    spec = CryptoGroups.Curve_P_256

    G = specialize(ECGroup, spec; name = :P_256)
    g = G <| generator(spec)

    elgamal_test(g)
end


# This one gives the UndefVarError(:P) error

let
    spec = CryptoGroups.Curve_B_163_PB
    G = specialize(ECGroup, spec; name = :B_163_PB)
    g = G <| generator(spec)

    elgamal_test(g)
end


