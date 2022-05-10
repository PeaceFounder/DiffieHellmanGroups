import Base: @kwdef

_parse_seed(seed::String) = hex2bytes(seed)
_parse_seed(seed::Vector{UInt8}) = seed

_parse_bits(x::String, N::Int) = hex2bits(x)[end - N + 1:end]
_parse_bits(x::BitVector, m::Int) = x
_parse_bits(x::Nothing, m::Int) = x


_parse_int(x::String) = parse(BigInt, x, base=16)
_parse_int(x::Integer) = BigInt(x)


function spec(::Type{P}; kwargs...) where P <: AbstractPoint

    n = hasmethod(order, Tuple{Type{P}}) ? order(P) : nothing
    h = hasmethod(cofactor, Tuple{Type{P}}) ? cofactor(P) : nothing

    EQ = eq(P)
    F = field(P)

    return spec(EQ, F; n, h, kwargs...)
end

spec(p::P) where P <: AbstractPoint = spec(P; Gx=value(gx(p)), Gy=value(gy(p)))


spec(::Type{ECGroup{P}}) where P = spec(P)
spec(g::ECGroup) = spec(g.p)



@kwdef struct ECP <: Spec
    p::BigInt
    n::Union{BigInt, Nothing} = nothing
    a::BigInt = -3
    b::BigInt
    Gx::Union{BigInt, Nothing} = nothing
    Gy::Union{BigInt, Nothing} = nothing
end

order(curve::ECP) = curve.n
generator(curve::ECP) = (curve.Gx, curve.Gy)

modulus(curve::ECP) = curve.p



function ECP(p, n, a, b, Gx, Gy)
    
    _a = mod(_parse_int(a), p) # taking mod as conventually a=-3
    _b = _parse_int(b)
    _Gx = _parse_int(Gx)
    _Gy = _parse_int(Gy)

    return ECP(p, n, _a, _b, _Gx, _Gy)
end

# I could always add a field for equation to be used

function spec(::Type{EQ}, ::Type{F}; n=nothing, h=nothing, Gx=nothing, Gy=nothing) where {EQ <: Weierstrass, F <: PrimeField}
    
    _a = a(EQ)
    _b = b(EQ)

    p = modulus(F)

    return ECP(p, n, _a, _b, Gx, Gy) # I will need to add H in the end here
end


Base.:(==)(x::ECP, y::ECP) = x.p == y.p && x.n == y.n && x.a == y.a && x.b == y.b && x.Gx == y.Gx && x.Gy == y.Gy


abstract type EC2N <: Spec end

order(curve::EC2N) = curve.n
generator(curve::EC2N) = (curve.Gx, curve.Gy)

a(curve::EC2N) = curve.a
b(curve::EC2N) = curve.b 


@kwdef struct Koblitz_GNB <: EC2N
    m::Int
    T::Int
    n::BigInt
    a::Int
    Gx::BitVector
    Gy::BitVector

    function Koblitz_GNB(m::Int, T::Int, n::BigInt, a::Int, Gx::BitVector, Gy::BitVector)
        
        @assert a in [0, 1]
        @assert length(Gx) == length(Gy) == m
        
        new(m, T, n, a, Gx, Gy)
    end
end

function Koblitz_GNB(m, T, n, a, Gx, Gy)

    _m = convert(Int, m)
    _T = convert(Int, T)
    _a = convert(Int, a)
    _n = convert(BigInt, n)
    _Gx = _parse_bits(Gx, _m)
    _Gy = _parse_bits(Gy, _m)

    return Koblitz_GNB(_m, _T, _n, _a, _Gx, _Gy)
end


function b(curve::Koblitz_GNB)
    
    (; m) = curve

    _b = 1
    b′ = _parse_bits_gnb(_b, m)

    return b′
end


@kwdef struct Koblitz_PB <: EC2N
    f::Vector{Int}
    n::BigInt
    a::Int
    Gx::BitVector
    Gy::BitVector

    function Koblitz_PB(f::Vector{Int}, n::BigInt, a::Int, Gx::BitVector, Gy::BitVector)
        
        m = maximum(f)

        @assert a in [0, 1]
        @assert length(Gx) == length(Gy) == m

        new(f, n, a, Gx, Gy)
    end
end

function Koblitz_PB(f, n, a, Gx, Gy)

    _f = convert(Vector{Int}, f)

    m = maximum(_f)

    _n = convert(BigInt, n)
    _a = convert(Int, a)
    _Gx = _parse_bits(Gx, m)
    _Gy = _parse_bits(Gy, m)

    return Koblitz_PB(_f, _n, _a, _Gx, _Gy)
end


function b(curve::Koblitz_PB) 

    (; f) = curve

    m = maximum(f)

    _b = 1
    b′ = _parse_bits_pb(_b, m)
    
    return b′
end



function _int2bits_gnb(x::Int, m::Int)
    if x == 0
        return BitVector(0 for i in 1:m)
    elseif x == 1
        return BitVector(1 for i in 1:m)
    else
        error("Conversion of $x not possible")
    end
end

_parse_bits_gnb(x::BitVector, m::Int) = x
_parse_bits_gnb(x::String, m::Int) = _parse_bits(x, m)
_parse_bits_gnb(x::Int, m::Int) = _int2bits_gnb(x, m)

#abstract type BinaryCurveSpec <: EllipticCurveSpec end

@kwdef struct BEC_GNB <: EC2N  #BinaryCurveSpec
    m::Int
    T::Int
    n::BigInt
    a::BitVector
    b::BitVector
    Gx::BitVector
    Gy::BitVector

    function BEC_GNB(m::Int, T::Int, n::BigInt, a::BitVector, b::BitVector, Gx::BitVector, Gy::BitVector)
        
        @assert m == length(a) == length(b) == length(Gx) == length(Gy)

        new(m, T, n, a, b, Gx, Gy)
    end
end

function BEC_GNB(m, T, n, a, b, Gx, Gy)
    
    _m = convert(Int, m)
    _T = convert(Int, T)
    _n = convert(BigInt, n)
    _a = _parse_bits_gnb(a, _m)
    _b = _parse_bits_gnb(b, _m)
    _Gx = _parse_bits(Gx, _m)
    _Gy = _parse_bits(Gy, _m)

    return BEC_GNB(_m, _T, _n, _a, _b, _Gx, _Gy)
end


function BEC_GNB(curve::Koblitz_GNB)
    
    (; m, T, n, a, Gx, Gy) = curve

    _b = b(curve)

    return BEC_GNB(m, T, n, a, _b, Gx, Gy)
end


function _int2bits_pb(x::Int, m::Int)
    if x == 0
        return BitVector(0 for i in 1:m)
    elseif x == 1
        return BitVector(((0 for i in 1:m-1)..., 1))
    else
        error("Conversion of $x not possible")
    end
end

_parse_bits_pb(x::BitVector, m::Int) = x
_parse_bits_pb(x::String, m::Int) = _parse_bits(x, m)
_parse_bits_pb(x::Int, m::Int) = _int2bits_pb(x, m)


@kwdef struct BEC_PB <: EC2N  #BinaryCurveSpec
    f::Vector{Int}
    n::BigInt
    a::BitVector   
    b::BitVector
    Gx::BitVector
    Gy::BitVector

    function BEC_PB(f::Vector{Int}, n::BigInt, a::BitVector, b::BitVector, Gx::BitVector, Gy::BitVector)
        
        m = maximum(f)

        @assert length(a) == length(b) == length(Gx) == length(Gy) == m

        new(f, n, a, b, Gx, Gy)
    end
end


function BEC_PB(f, n, a, b, Gx, Gy)
    
    _f = convert(Vector{Int}, f)
    _m = maximum(_f)
    _n = convert(BigInt, n)
    
    _a = _parse_bits_pb(a, _m)
    _b = _parse_bits_pb(b, _m)
    _Gx = _parse_bits(Gx, _m)
    _Gy = _parse_bits(Gy, _m)

    return BEC_PB(_f, _n, _a, _b, _Gx, _Gy)
end



function BEC_PB(curve::Koblitz_PB)
    
    (; f, n, a, Gx, Gy) = curve

    _b = b(curve)

    return BEC_PB(f, n, a, _b, Gx, Gy)
end

### Methods for making a concrete AffinePoint type from given elliptic curve spec

function specialize(::Type{AffinePoint{Weierstrass, F}}, curve::ECP) where F <: PrimeField

    (; p, a, b) = curve

    P = AffinePoint{specialize(Weierstrass, a, b), specialize(F, p)}
    
    return P
end

specialize(::Type{AffinePoint}, spec::ECP) = specialize(AffinePoint{Weierstrass, FP}, spec)
#specialize(::Type{ECPoint}, spec::ECP; name = nothing) = specialize(ECPoint{AffinePoint}, spec; name)


function specialize(::Type{F}, curve::BEC_PB) where F <: BinaryField
    (; f) = curve
    return specialize(F, f)
end

function specialize(::Type{F}, curve::BEC_GNB) where F <: BinaryField
    (; m, T) = curve
    return specialize(F, m, T)
end

specialize(::Type{BinaryCurve}, curve::EC2N) = specialize(BinaryCurve, a(curve), b(curve))

function specialize(::Type{AffinePoint{BinaryCurve, F}}, curve) where F <: BinaryField
    P = AffinePoint{specialize(BinaryCurve, curve), specialize(F, curve)}
    return P
end

specialize(::Type{AffinePoint}, curve::BEC_GNB) = specialize(AffinePoint{BinaryCurve, F2GNB}, curve)
specialize(::Type{AffinePoint}, curve::BEC_PB) = specialize(AffinePoint{BinaryCurve, F2PB}, curve)

specialize(::Type{AffinePoint{BinaryCurve, F}}, curve::Koblitz_GNB) where F <: BinaryField = specialize(AffinePoint{BinaryCurve, F}, BEC_GNB(curve))
specialize(::Type{AffinePoint{BinaryCurve, F}}, curve::Koblitz_PB) where F <: BinaryField = specialize(AffinePoint{BinaryCurve, F}, BEC_PB(curve))


################################ Constants #################

############### Prime curves #############

# 
const Curve_P_192 = ECP(
    p = 6277101735386680763835789423207666416083908700390324961279,
    n = 6277101735386680763835789423176059013767194773182842284081,
    #SEED = "3045ae6f c8422f64 ed579528 d38120ea e12196d5",
    #c = "3099d2bb bfcb2538 542dcd5f b078b6ef 5f3d6fe2 c745de65",
    b = "64210519 e59c80e7 0fa7e9ab 72243049 feb8deec c146b9b1",
    Gx = "188da80e b03090f6 7cbf20eb 43a18800 f4ff0afd 82ff1012",
    Gy = "07192b95 ffc8da78 631011ed 6b24cdd5 73f977a1 1e794811"
)

const Curve_P_244 = ECP(
    p = 26959946667150639794667015087019630673557916260026308143510066298881,
    n = 26959946667150639794667015087019625940457807714424391721682722368061, 
    # SEED = "bd713447 99d5c7fc dc45b59f a3b9ab8f 6a948bc5",
    # c = "5b056c7e 11dd68f4 0469ee7f 3c7a7d74 f7d12111 6506d031 218291fb", 
    b = "b4050a85 0c04b3ab f5413256 5044b0b7 d7bfd8ba 270b3943 2355ffb4",
    Gx = "b70e0cbd 6bb4bf7f 321390b9 4a03c1d3 56c21122 343280d6 115c1d21", 
    Gy = "bd376388 b5f723fb 4c22dfe6 cd4375a0 5a074764 44d58199 85007e34"    
)

const Curve_P_256 = ECP(
    p = 115792089210356248762697446949407573530086143415290314195533631308867097853951,
    n = 115792089210356248762697446949407573529996955224135760342422259061068512044369,
    #SEED = "c49d3608 86e70493 6a6678e1 139d26b7 819f7e90",
    #c = "7efba166 2985be94 03cb055c 75d4f7e0 ce8d84a9 c5114abc af317768 0104fa0d",
    b = "5ac635d8 aa3a93e7 b3ebbd55 769886bc 651d06b0 cc53b0f6 3bce3c3e 27d2604b",
    Gx = "6b17d1f2 e12c4247 f8bce6e5 63a440f2 77037d81 2deb33a0 f4a13945 d898c296",
    Gy = "4fe342e2 fe1a7f9b 8ee7eb4a 7c0f9e16 2bce3357 6b315ece cbb64068 37bf51f5"   
)

const Curve_P_384 = ECP(
    p = 39402006196394479212279040100143613805079739270465446667948293404245721771496870329047266088258938001861606973112319,
    n = 39402006196394479212279040100143613805079739270465446667946905279627659399113263569398956308152294913554433653942643,
    #SEED = "a335926a a319a27a 1d00896a 6773a482 7acdac73",
    #c = "79d1e655 f868f02f ff48dcde e14151dd b80643c1 406d0ca1 0dfe6fc5 2009540a 495e8042 ea5f744f 6e184667 cc722483",
    b = "b3312fa7 e23ee7e4 988e056b e3f82d19 181d9c6e fe814112 0314088f 5013875a c656398d 8a2ed19d 2a85c8ed d3ec2aef",
    Gx = "aa87ca22 be8b0537 8eb1c71e f320ad74 6e1d3b62 8ba79b98 59f741e0 82542a38 5502f25d bf55296c 3a545e38 72760ab7", 
    Gy = "3617de4a 96262c6f 5d9e98bf 9292dc29 f8f41dbd 289a147c e9da3113 b5f0b8c0 0a60b1ce 1d7e819d 7a431d7c 90ea0e5f"
)

const Curve_P_521 = ECP(
    p = 6864797660130609714981900799081393217269435300143305409394463459185543183397656052122559640661454554977296311391480858037121987999716643812574028291115057151,
    n = 6864797660130609714981900799081393217269435300143305409394463459185543183397655394245057746333217197532963996371363321113864768612440380340372808892707005449, 
    #SEED = "d09e8800 291cb853 96cc6717 393284aa a0da64ba",
    #c = "0b4 8bfa5f42 0a349495 39d2bdfc 264eeeeb 077688e4 4fbf0ad8 f6d0edb3 7bd6b533 28100051 8e19f1b9 ffbe0fe9 ed8a3c22 00b8f875 e523868c 70c1e5bf 55bad637",
    b = "051 953eb961 8e1c9a1f 929a21a0 b68540ee a2da725b 99b315f3 b8b48991 8ef109e1 56193951 ec7e937b 1652c0bd 3bb1bf07 3573df88 3d2c34f1 ef451fd4 6b503f00", 
    Gx = "c6 858e06b7 0404e9cd 9e3ecb66 2395b442 9c648139 053fb521 f828af60 6b4d3dba a14b5e77 efe75928 fe1dc127 a2ffa8de 3348b3c1 856a429b f97e7e31 c2e5bd66", 
    Gy = "118 39296a78 9a3bc004 5c8a5fb4 2c7d1bd9 98f54449 579b4468 17afbd17 273e662c 97ee7299 5ef42640 c550b901 3fad0761 353c7086 a272c240 88be9476 9fd16650"
)

############### Koblitz curves ################

const Curve_K_163_PB = Koblitz_PB(
    f = [163, 7, 6, 3, 0],
    a = 1,
    n = 5846006549323611672814741753598448348329118574063,
    Gx = "2 fe13c053 7bbc11ac aa07d793 de4e6d5e 5c94eee8", 
    Gy = "2 89070fb0 5d38ff58 321f2e80 0536d538 ccdaa3d9"
)

const Curve_K_163_GNB = Koblitz_GNB(
    n = 5846006549323611672814741753598448348329118574063,
    a = 1,
    m = 163,
    T = 4,
    Gx = "0 5679b353 caa46825 fea2d371 3ba450da 0c2a4541", 
    Gy = "2 35b7c671 00506899 06bac3d9 dec76a83 5591edb2"
)


const Curve_K_233_PB = Koblitz_PB(
    f = [233, 74, 0],
    a = 0,
    n = 3450873173395281893717377931138512760570940988862252126328087024741343,
    Gx = "172 32ba853a 7e731af1 29f22ff4 149563a4 19c26bf5 0a4c9d6e efad6126",
    Gy = "1db 537dece8 19b7f70f 555a67c4 27a8cd9b f18aeb9b 56e0c110 56fae6a3"
)

const Curve_K_233_GNB = Koblitz_GNB(
    m = 233,
    T = 2,
    a = 0,
    n = 3450873173395281893717377931138512760570940988862252126328087024741343,
    Gx = "0fd e76d9dcd 26e643ac 26f1aa90 1aa12978 4b71fc07 22b2d056 14d650b3",
    Gy = "064 3e317633 155c9e04 47ba8020 a3c43177 450ee036 d6335014 34cac978"
)

const Curve_K_283_PB = Koblitz_PB(
    f = [283, 12, 7, 5, 0],
    a = 0,
    n = 3885337784451458141838923813647037813284811733793061324295874997529815829704422603873,
    Gx = "503213f 78ca4488 3f1a3b81 62f188e5 53cd265f 23c1567a 16876913 b0c2ac24 58492836", 
    Gy = "1ccda38 0f1c9e31 8d90f95d 07e5426f e87e45c0 e8184698 e4596236 4e341161 77dd2259"
)

const Curve_K_283_GNB = Koblitz_GNB(
    m = 283,
    T = 6,
    a = 0,
    n = 3885337784451458141838923813647037813284811733793061324295874997529815829704422603873,
    Gx = "3ab9593 f8db09fc 188f1d7c 4ac9fcc3 e57fcd3b db15024b 212c7022 9de5fcd9 2eb0ea60",
    Gy = "2118c47 55e7345c d8f603ef 93b98b10 6fe8854f feb9a3b3 04634cc8 3a0e759f 0c2686b1"
)

const Curve_K_409_PB = Koblitz_PB(
    f = [409, 87, 0],
    a = 0,
     n = 330527984395124299475957654016385519914202341482140609642324395022880711289249191050673258457777458014096366590617731358671,
    Gx = "060f05f 658f49c1 ad3ab189 0f718421 0efd0987 e307c84c 27accfb8 f9f67cc2 c460189e b5aaaa62 ee222eb1 b35540cf e9023746", 
    Gy = "1e36905 0b7c4e42 acba1dac bf04299c 3460782f 918ea427 e6325165 e9ea10e3 da5f6c42 e9c55215 aa9ca27a 5863ec48 d8e0286b"
)

const Curve_K_409_GNB = Koblitz_GNB(
    m = 409,
    T = 4,
    a = 0,
    n = 330527984395124299475957654016385519914202341482140609642324395022880711289249191050673258457777458014096366590617731358671,
    Gx = "1b559c7 cba2422e 3affe133 43e808b5 5e012d72 6ca0b7e6 a63aeafb c1e3a98e 10ca0fcf 98350c3b 7f89a975 4a8e1dc0 713cec4a",
    Gy = "16d8c42 052f07e7 713e7490 eff318ba 1abd6fef 8a5433c8 94b24f5c 817aeb79 852496fb ee803a47 bc8a2038 78ebf1c4 99afd7d6"
)

const Curve_K_571_PB = Koblitz_PB(
    f = [571, 10, 5, 2, 0],
    n = 1932268761508629172347675945465993672149463664853217499328617625725759571144780212268133978522706711834706712800825351461273674974066617311929682421617092503555733685276673,
    a = 0,
    Gx = "26eb7a8 59923fbc 82189631 f8103fe4 ac9ca297 0012d5d4 60248048 01841ca4 43709584 93b205e6 47da304d b4ceb08c bbd1ba39 494776fb 988b4717 4dca88c7 e2945283 a01c8972",
    Gy = "349dc80 7f4fbf37 4f4aeade 3bca9531 4dd58cec 9f307a54 ffc61efc 006d8a2c 9d4979c0 ac44aea7 4fbebbb9 f772aedc b620b01a 7ba7af1b 320430c8 591984f6 01cd4c14 3ef1c7a3"
)

const Curve_K_571_GNB = Koblitz_GNB(
    m = 571,
    T = 10,
    a = 0,
    n = 1932268761508629172347675945465993672149463664853217499328617625725759571144780212268133978522706711834706712800825351461273674974066617311929682421617092503555733685276673,
    Gx = "04bb2db a418d0db 107adae0 03427e5d 7cc139ac b465e593 4f0bea2a b2f3622b c29b3d5b 9aa7a1fd fd5d8be6 6057c100 8e71e484 bcd98f22 bf847642 37673674 29ef2ec5 bc3ebcf7",
    Gy = "44cbb57 de20788d 2c952d7b 56cf39bd 3e89b189 84bd124e 751ceff4 369dd8da c6a59e6e 745df44d 8220ce22 aa2c852c fcbbef49 ebaa98bd 2483e331 80e04286 feaa2530 50caff60"
)


##################### Binary curves ############################


const Curve_B_163_PB = BEC_PB(
    f = [163, 7, 6, 3, 0],
    a = 1,
    b = "2 0a601907 b8c953ca 1481eb10 512f7874 4a3205fd",
    n = 5846006549323611672814742442876390689256843201587,
    Gx = "3 f0eba162 86a2d57e a0991168 d4994637 e8343e36", 
    Gy = "0 d51fbc6c 71a0094f a2cdd545 b11c5c0c 797324f1"    
)

const Curve_B_163_GNB = BEC_GNB(
    m = 163,
    T = 4,
    a = 1,
    b = "6 645f3cac f1638e13 9c6cd13e f61734fb c9e3d9fb",
    n = 5846006549323611672814742442876390689256843201587,
    Gx = "0 311103c1 7167564a ce77ccb0 9c681f88 6ba54ee8",
    Gy = "3 33ac13c6 447f2e67 613bf700 9daf98c8 7bb50c7f"
)


const Curve_B_233_PB = BEC_PB(
    f = [233, 74, 0],
    a = 1,
    b = "066 647ede6c 332c7f8c 0923bb58 213b333b 20e9ce42 81fe115f 7d8f90ad",
    n = 6901746346790563787434755862277025555839812737345013555379383634485463,
    Gx = "0fa c9dfcbac 8313bb21 39f1bb75 5fef65bc 391f8b36 f8f8eb73 71fd558b",
    Gy = "100 6a08a419 03350678 e58528be bf8a0bef f867a7ca 36716f7e 01f81052"
)

const Curve_B_233_GNB = BEC_GNB(
    m = 233,
    T = 2,
    a = 1,
    b = "1a0 03e0962d 4f9a8e40 7c904a95 38163adb 82521260 0c7752ad 52233279",
    n = 6901746346790563787434755862277025555839812737345013555379383634485463,
    Gx = "18b 863524b3 cdfefb94 f2784e0b 116faac5 4404bc91 62a363ba b84a14c5",
    Gy = "049 25df77bd 8b8ff1a5 ff519417 822bfedf 2bbd7526 44292c98 c7af6e02"
)

const Curve_B_283_PB = BEC_PB(
    f = [283, 12, 7, 5, 0],
    n = 770675568902916283677847627294075626569625924376904889109196526770044277787378692871,
    a = 1,
    b = "27b680a c8b8596d a5a4af8a 19a0303f ca97fd76 45309fa2 a581485a f6263e31 3b79a2f5",
    Gx = "5f93925 8db7dd90 e1934f8c 70b0dfec 2eed25b8 557eac9c 80e2e198 f8cdbecd 86b12053", 
    Gy = "3676854 fe24141c b98fe6d4 b20d02b4 516ff702 350eddb0 826779c8 13f0df45 be8112f4"
)

const Curve_B_283_GNB = BEC_GNB(
    m = 283,
    T = 6,
    a = 1,
    b = "157261b 894739fb 5a13503f 55f0b3f1 0c560116 66331022 01138cc1 80c0206b dafbc951",
    n = 7770675568902916283677847627294075626569625924376904889109196526770044277787378692871,
    Gx = "749468e 464ee468 634b21f7 f61cb700 701817e6 bc36a236 4cb8906e 940948ea a463c35d",
    Gy = "62968bd 3b489ac5 c9b859da 68475c31 5bafcdc4 ccd0dc90 5b70f624 46f49c05 2f49c08c"
)

const Curve_B_409_PB = BEC_PB(
    f = [409, 87, 0],
    n = 661055968790248598951915308032771039828404682964281219284648798304157774827374805208143723762179110965979867288366567526771,
    a = 1,
    b = "021a5c2 c8ee9feb 5c4b9a75 3b7b476b 7fd6422e f1f3dd67 4761fa99 d6ac27c8 a9a197b2 72822f6c d57a55aa 4f50ae31 7b13545f", 
    Gx = "15d4860 d088ddb3 496b0c60 64756260 441cde4a f1771d4d b01ffe5b 34e59703 dc255a86 8a118051 5603aeab 60794e54 bb7996a7",
    Gy = "061b1cf ab6be5f3 2bbfa783 24ed106a 7636b9c5 a7bd198d 0158aa4f 5488d08f 38514f1f df4b4f40 d2181b36 81c364ba 0273c706"
)

const Curve_B_409_GNB = BEC_GNB(
    m = 409,
    T = 4,
    a = 1,
    b = "124d065 1c3d3772 f7f5a1fe 6e715559 e2129bdf a04d52f7 b6ac7c53 2cf0ed06 f610072d 88ad2fdc c50c6fde 72843670 f8b3742a",
    n = 661055968790248598951915308032771039828404682964281219284648798304157774827374805208143723762179110965979867288366567526771,
    Gx = "0ceacbc 9f475767 d8e69f3b 5dfab398 13685262 bcacf22b 84c7b6dd 981899e7 318c96f0 761f77c6 02c016ce d7c548de 830d708f",
    Gy = "199d64b a8f089c6 db0e0b61 e80bb959 34afd0ca f2e8be76 d1c5e9af fc7476df 49142691 ad303902 88aa09bc c59c1573 aa3c009a"
)

const Curve_B_571_PB = BEC_PB(
    f = [571, 10, 5, 2, 0],
    n = 3864537523017258344695351890931987344298927329706434998657235251451519142289560424536143999389415773083133881121926944486246872462816813070234528288303332411393191105285703,
    a = 1,
    b = "2f40e7e 2221f295 de297117 b7f3d62f 5c6a97ff cb8ceff1 cd6ba8ce 4a9a18ad 84ffabbd 8efa5933 2be7ad67 56a66e29 4afd185a 78ff12aa 520e4de7 39baca0c 7ffeff7f 2955727a", 
    Gx = "303001d 34b85629 6c16c0d4 0d3cd775 0a93d1d2 955fa80a a5f40fc8 db7b2abd bde53950 f4c0d293 cdd711a3 5b67fb14 99ae6003 8614f139 4abfa3b4 c850d927 e1e7769c 8eec2d19", 
    Gy = "37bf273 42da639b 6dccfffe b73d69d7 8c6c27a6 009cbbca 1980f853 3921e8a6 84423e43 bab08a57 6291af8f 461bb2a8 b3531d2f 0485c19b 16e2f151 6e23dd3c 1a4827af 1b8ac15b"
)

const Curve_B_571_GNB = BEC_GNB(
    m = 571,
    T = 10,
    a = 1,
    b = "3762d0d 47116006 179da356 88eeaccf 591a5cde a7500011 8d9608c5 9132d434 26101a1d fb377411 5f586623 f75f0000 1ce61198 3c1275fa 31f5bc9f 4be1a0f4 67f01ca8 85c74777",
    n = 3864537523017258344695351890931987344298927329706434998657235251451519142289560424536143999389415773083133881121926944486246872462816813070234528288303332411393191105285703,
    Gx = "0735e03 5def5925 cc33173e b2a8ce77 67522b46 6d278b65 0a291612 7dfea9d2 d361089f 0a7a0247 a184e1c7 0d417866 e0fe0feb 0ff8f2f3 f9176418 f97d117e 624e2015 df1662a8",
    Gy = "04a3642 0572616c df7e606f ccadaecf c3b76dab 0eb1248d d03fbdfc 9cd3242c 4726be57 9855e812 de7ec5c5 00b4576a 24628048 b6a72d88 0062eed0 dd34b109 6d3acbb6 b01a4a97"
)
