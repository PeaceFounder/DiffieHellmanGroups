# Point conversion routines
using Test
import CryptoGroups.Specs: bits2octet, octet2bits, int2octet, octet2int, ECP, octet, point, EC2N, PB
import CryptoGroups: @bin_str, bitlength

_hex2bytes(x) = hex2bytes(join(split(x, " "), ""))

let 
    x = UInt8[0, 129]
    @test bits2octet(octet2bits(x)) == x

    a = octet2bits(x)
    # First leftmostbits are padded to zero to make a full octet
    @test bits2octet(a[4:end]) == bits2octet(a)

    @test octet2bits(x, 13) == octet2bits(x)[4:end]
end

@test int2octet(123456789, 4) == hex2bytes("075BCD15")

@test octet2int("0003ABF1CD") == 61600205

@test int2octet(94311, bitlength(104729)) == hex2bytes("017067")

@test bits2octet(bin"11011011011101111001101111110110111110001") == hex2bytes("01B6EF37EDF1")

@test octet2int("01E74E") == 124750

@test octet2bits("0117B2939ACC", 41) == bin"10001011110110010100100111001101011001100"

# Field element to integer conversion

@test octet2int(bits2octet(bin"11111111001000010011110000110011110101110")) == 2191548508078

let

    prime_curve = ECP(
        p = 6277101735386680763835789423207666416083908700390324961279,
        n = 0, 
        a = 6277101735386680763835789423207666416083908700390324961276,
        b = 2455155546008943817740293915197451784769108058161191238065
    )

    xp = 602046282375688656758213480587526111916698976636884684818 
    yp = 174050332293622031404857552280219410364023488927386650641


    @test octet(xp, yp, bitlength(prime_curve); mode = :compressed) == _hex2bytes("03 188DA80E B03090F6 7CBF20EB 43A18800 F4FF0AFD 82FF1012")
    @test point(_hex2bytes("03 188DA80E B03090F6 7CBF20EB 43A18800 F4FF0AFD 82FF1012"), prime_curve) == (xp, yp)

    @test octet(xp, yp, bitlength(prime_curve); mode = :uncompressed) == _hex2bytes("04 188DA80E B03090F6 7CBF20EB 43A18800 F4FF0AFD 82FF1012 07192B95 FFC8DA78 631011ED 6B24CDD5 73F977A1 1E794811")
    @test point(_hex2bytes("04 188DA80E B03090F6 7CBF20EB 43A18800 F4FF0AFD 82FF1012 07192B95 FFC8DA78 631011ED 6B24CDD5 73F977A1 1E794811"), prime_curve) == (xp, yp)


    @test octet(xp, yp, bitlength(prime_curve); mode = :hybrid) == _hex2bytes("07 188DA80E B03090F6 7CBF20EB 43A18800 F4FF0AFD 82FF1012 07192B95 FFC8DA78 631011ED 6B24CDD5 73F977A1 1E794811")
    @test point(_hex2bytes("07 188DA80E B03090F6 7CBF20EB 43A18800 F4FF0AFD 82FF1012 07192B95 FFC8DA78 631011ED 6B24CDD5 73F977A1 1E794811"), prime_curve) == (xp, yp)

end

### Now the binary curve with polynomial basis
let

    f = octet2bits(hex2bytes("800000000000000000000000000000000000000000000201"), 192)

    a = octet2bits(_hex2bytes("2866537B 67675263 6A68F565 54E12640 276B649E F7526267"), 191)
    b = octet2bits(_hex2bytes("2866537B 67675263 6A68F565 54E12640 276B649E F7526267"), 191)

    binary_curve = EC2N{PB}(
        f = f,
        a = a,
        b = b,
        n = 0,
    )

    xp = bin"01101101011001111011010111110001010001000110010000001101111100111000100111100101001100111010111101100100001101010011100001101101001000100110111111100101100100001001010111000011010101000001101"
    yp = bin"11101100101101111100111001101000011001110110011111110010101111000110011001010010011001011100111000011101010001001000101110010100010010000011000111010100000111011111001100000000001100011111011"


    @test octet(xp, yp, PB(f); mode = :uncompressed) == _hex2bytes("04 36B3DAF8 A23206F9 C4F299D7 B21A9C36 9137F2C8 4AE1AA0D 765BE734 33B3F95E 332932E7 0EA245CA 2418EA0E F98018FB")
    @test point(_hex2bytes("04 36B3DAF8 A23206F9 C4F299D7 B21A9C36 9137F2C8 4AE1AA0D 765BE734 33B3F95E 332932E7 0EA245CA 2418EA0E F98018FB"), binary_curve) == (xp, yp)


    @test octet(xp, yp, PB(f); mode = :compressed) == _hex2bytes("02 36B3DAF8 A23206F9 C4F299D7 B21A9C36 9137F2C8 4AE1AA0D")

    @test octet(xp, yp, PB(f); mode = :hybrid) == _hex2bytes("06 36B3DAF8 A23206F9 C4F299D7 B21A9C36 9137F2C8 4AE1AA0D 765BE734 33B3F95E 332932E7 0EA245CA 2418EA0E F98018FB")
    @test point(_hex2bytes("06 36B3DAF8 A23206F9 C4F299D7 B21A9C36 9137F2C8 4AE1AA0D 765BE734 33B3F95E 332932E7 0EA245CA 2418EA0E F98018FB"), binary_curve) == (xp, yp)

end

### Now reading of the point
let

    prime_curve = ECP(
        p = 6277101735386680763835789423207666416083908700390324961279,
        n = 0, 
        a = 6277101735386680763835789423207666416083908700390324961276,
        b = 5005402392289390203552069470771117084861899307801456990547
    )

    @test point(_hex2bytes("03 EEA2BAE7 E1497842 F2DE7769 CFE9C989 C072AD69 6F48034A"), prime_curve) == (5851329466723574623122023978072381191095567081251774399306, 2487701625881228691269808880535093938601070911264778280469)

end

### Last part of converting binary curve to a compressed point

let

    f = octet2bits(hex2bytes("800000000000000000000000000000000000000000000201"), 192)

    a = octet2bits(_hex2bytes("40102877 4D7777C7 B7666D13 66EA4320 71274F89 FF01E718"), 191)
    b = octet2bits(_hex2bytes("0620048D 28BCBD03 B6249C99 182B7C8C D19700C3 62C46A01"), 191)

    binary_curve = EC2N{PB}(
        f = f,
        a = a,
        b = b,
        n = 0,
    )

    PO = "02 3809B2B7 CC1B28CC 5A87926A AD83FD28 789E81E2 C9E3BF10"

    xp = bin"01110000000100110110010101101111100110000011011001010001100110001011010100001111001001001101010101011011000001111111101001010000111100010011110100000011110001011001001111000111011111100010000"
    yp = bin"00101110100001101000011100001100110001001101101000101001111001111011011111100000001011101100000110110010010000100111010001111100001110011110011011110101110110001000011011111010110011010001010"

    # point(_hex2bytes(PO), binary_curve) == (xp, yp)
end


using CryptoGroups: spec, specialize, ECPoint, AffinePoint, Weierstrass, FP, generator, <|, F2PB, BinaryCurve, F2GNB

import CryptoGroups

let

    _spec = spec(:P_192)

    P = specialize(ECPoint{AffinePoint{Weierstrass, FP}}, _spec)
    g = P <| generator(_spec)
    @test P <| octet(g; mode = :uncompressed) == g
    @test P <| octet(g; mode = :compressed) == g
    @test P <| octet(g; mode = :hybrid) == g

end


let

    _spec = CryptoGroups.Specs.Curve_B_163_PB

    P = specialize(ECPoint{AffinePoint{BinaryCurve, F2PB}}, _spec)
    g = P <| generator(_spec)
    @test P <| octet(g; mode = :uncompressed) == g
    #@test P <| octet(g; mode = :compressed) == g
    @test P <| octet(g; mode = :hybrid) == g
end

let
    _spec = CryptoGroups.Specs.Curve_B_163_GNB

    P = specialize(ECPoint{AffinePoint{BinaryCurve, F2GNB}}, _spec)
    g = P <| generator(_spec)
    @test P <| octet(g; mode = :uncompressed) == g
    #@test P <| octet(g; mode = :compressed) == g
    @test P <| octet(g; mode = :hybrid) == g
end


let

    _spec = CryptoGroups.Specs.Curve_K_163_PB

    P = specialize(ECPoint{AffinePoint{BinaryCurve, F2PB}}, _spec)
    g = P <| generator(_spec)
    @test P <| octet(g; mode = :uncompressed) == g
    #@test P <| octet(g; mode = :compressed) == g
    @test P <| octet(g; mode = :hybrid) == g
end
