// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/complexMath/Complex.sol";
import {PRBMathSD59x18} from "../src/complexMath/prbMath/PRBMathSD59x18.sol";

contract ComplexTest is Test {
    WRAPPER public complex;
    int256 scale = 1e18;
    int256 scale2 = 1e19;

    function setUp() public {
        complex = WRAPPER(HuffDeployer.deploy("ComplexHuff/WRAPPER"));
    }

    function testSubZ() public {
        (int256 r, int256 i) = complex.subz(4 * scale, 5 * scale, 8 * scale, 11 * scale);
        assertEq(r / scale, 3);
        assertEq(i / scale, 1);
    }

    function testAddZ() public {
        (int256 r, int256 i) = complex.addz(2 * scale, 3 * scale, 4 * scale, 5 * scale);
        assertEq(r / scale, 9);
        assertEq(i / scale, 5);
    }

    function testMulZ() public {
        (int256 r, int256 i) = complex.mulz(2 * scale, 3 * scale, 4 * scale, 5 * scale);
        assertEq((r / scale) / scale, 14);
        assertEq((i / scale) / scale, 22);
    }

    function testDivZ() public {
        (int256 r, int256 i) = complex.divz(7 * scale, 1 * scale, 5 * scale, 2 * scale);
        assertEq((r * 10) / scale, 2); // 17/74
        assertEq((i * 10) / scale, -1); // -8/74
    }

    function testCalcR() public {
        uint256 r = complex.calcR(4 * scale, 4 * scale);
        assertEq(r / uint256(scale), 5);
    }

    function testToPolar() public {
        (int256 r, int256 t) = complex.toPolar(3, 4);
        assertEq(r, 5);
        assertEq((t * 100) / scale, 65);
    }

    function testFromPolar() public {
        (int256 r, int256 i) = complex.fromPolar(5 * scale, 92729522 * 1e10);
        assertApproxEqAbs(r, 3 * scale, 1e15);
        assertApproxEqAbs(i, 4 * scale, 1e15);
    }

    function testSqrt() public {
        (int256 r, int256 i) = complex.sqrt(12 * scale, -5 * scale);
        assertEq(r / scale, 2);
        assertEq(i / scale, 3);
    }

    function testExpZ() public {
        (int256 r, int256 i) = complex.expZ(92729522 * 1e10, 1);
        assertApproxEqAbs(r, 1630800000000000000, 1e15);
        assertApproxEqAbs(i, 2174400000000000000, 1e15);
    }

    function testPowZ() public {
        (int256 r, int256 i) = complex.pow(2, 3 * scale, 2 * scale);
        assertApproxEqAbs(r, -5 * scale, 5e17);
        assertApproxEqAbs(i, 12 * scale, 5e17);
    }

    function testLnZ() public {
        (int256 r, int256 i) = complex.ln(30 * scale, 40 * scale);
        assertEq((r * 100) / scale, 391); // ln(50) = 3.912..
        assertEq((i * 100) / scale, 65);
    }

    function testAtan2() public {
        int256 r = complex.p_atan2(4 * scale, 3 * scale);
        assertEq((r * 100) / scale, 6124);
    }

    function testAtan1to1() public {
        int256 r = complex.atan1to1(9 * 1e17);
        assertEq((r * 100) / scale, 73);
    }

    // bi,ai,br,ar
    // We can say the Addition function is correct if
    // it follows the properties of addition of complex numbers
    // i.e. Closure,Commutative,Associative,
    // Existance of Additive Identity and Additive Inverse
    function testAddZFuzz(int256 bi, int256 ai, int256 ci, int256 br, int256 ar, int256 cr) public {
        //bounded input to avoid underflow or overflow
        bi = bound(bi, -1e40, 1e40);
        ai = bound(ai, -1e40, 1e40);
        ci = bound(ci, -1e40, 1e40);
        br = bound(br, -1e40, 1e40);
        ar = bound(ar, -1e40, 1e40);
        cr = bound(cr, -1e40, 1e40);
        (int256 complexA_Br,int256 complexA_Bi)=(complex.addz(bi,ai,br,ar));                                            //A+B
        (int256 complexB_Ar,int256 complexB_Ai)=(complex.addz(ai,bi,ar,br));                                            //B+A
        (int256 complexB_Cr,int256 complexB_Ci)=(complex.addz(ci,bi,cr,br));                                            //B+C
        (int256 complexAB_Cr,int256 complexAB_Ci) = (complex.addz(ci,complexA_Bi,cr,complexA_Br));                      //(A+B)+C
        (int256 complexA_BCr,int256 complexA_BCi) = (complex.addz(complexB_Ci,ai,complexB_Cr,ar));                      //A+(B+c)
        (int256 complexA_0r ,int256 complexA_0i)= (complex.addz(0,ai,0,ar));                                            //A + 0
        (int256 complexA__Ar,int256 complexA__Ai) = (complex.addz(-(ai),ai,-(ar),ar));                                  //A + (-A)
        //Commutative A + B = B + A
        assertEq(complexA_Br,complexB_Ar);
        assertEq(complexA_Bi,complexB_Ai);
        //Associative (A+B)+C = A+(B+C)
        assertEq(complexAB_Cr,complexA_BCr);
        assertEq(complexAB_Ci,complexA_BCi);
        // Existance of additive identity A+0=A
        assertEq(complexA_0r,ar);
        assertEq(complexA_0i,ai);
        //Existance of additive inverse A + (-A)=0
        assertEq(complexA__Ar,0);
        assertEq(complexA__Ai,0);
    }

    function testSubZFuzz(int256 bi, int256 ai, int256 ci, int256 br, int256 ar, int256 cr) public {
        //bounded input to avoid underflow or overflow
        vm.assume(ai!=bi);
        vm.assume(bi!=ci);
        vm.assume(ai!=ci);
        vm.assume(ar!=br);
        vm.assume(br!=cr);
        vm.assume(ar!=cr);
        vm.assume(bi!=0);
        vm.assume(ai!=0);
        vm.assume(ci!=0);
        vm.assume(ar!=0);
        vm.assume(br!=0);
        vm.assume(cr!=0);
        bi = bound(bi, -1e40, 1e40);
        ai = bound(ai, -1e40, 1e40);
        ci = bound(ci, -1e40, 1e40);
        br = bound(br, -1e40, 1e40);
        ar = bound(ar, -1e40, 1e40);
        cr = bound(cr, -1e40, 1e40);
        (int256 complexA_Br,int256 complexA_Bi)=(complex.subz(bi,ai,br,ar));                                            //A-B
        (int256 complexB_Ar,int256 complexB_Ai)=(complex.subz(ai,bi,ar,br));                                            //B-A
        (int256 complexB_Cr,int256 complexB_Ci)=(complex.subz(ci,bi,cr,br));                                            //B-C
        (int256 complexAB_Cr,int256 complexAB_Ci) = (complex.subz(ci,complexA_Bi,cr,complexA_Br));                      //(A-B)-C
        (int256 complexA_BCr,int256 complexA_BCi) = (complex.subz(complexB_Ci,ai,complexB_Cr,ar));                      //A-(B-c)
        (int256 complexA_0r ,int256 complexA_0i)= (complex.subz(0,ai,0,ar));                                            //A - 0

        //Commutative A - B != B - A
        assertFalse(complexA_Br==complexB_Ar);
        assertFalse(complexA_Bi==complexB_Ai);
        //Associative (A-B)-C != A-(B-C)
        assertFalse(complexAB_Cr==complexA_BCr);
        assertFalse(complexAB_Ci==complexA_BCi);
        // Existance of additive identity A-0=A
        assertEq(complexA_0r,ar);
        assertEq(complexA_0i,ai);
    }

    function testMulZFuzz(int256 bi, int256 ai, int256 ci, int256 br, int256 ar, int256 cr) public {
        //bounded input to avoid underflow or overflow
        vm.assume(ai != bi);
        vm.assume(bi != ci);
        vm.assume(ai != ci);
        vm.assume(ar != br);
        vm.assume(br != cr);
        vm.assume(ar != cr);
        vm.assume(bi != -1);
        vm.assume(ai != -1);
        vm.assume(ci != -1);
        vm.assume(ar != -1);
        vm.assume(br != -1);
        vm.assume(cr != -1);
        vm.assume(bi != 1);
        vm.assume(ai != 1);
        vm.assume(ci != 1);
        vm.assume(ar != 1);
        vm.assume(br != 1);
        vm.assume(cr != 1);
        vm.assume(bi != 0);
        vm.assume(ai != 0);
        vm.assume(ci != 0);
        vm.assume(ar != 0);
        vm.assume(br != 0);
        vm.assume(cr != 0);
        bi = bound(bi, -1e10, 1e10);
        ai = bound(ai, -1e10, 1e10);
        ci = bound(ci, -1e10, 1e10);
        br = bound(br, -1e10, 1e10);
        ar = bound(ar, -1e10, 1e10);
        cr = bound(cr, -1e10, 1e10);
        (int256 complexA_Br, int256 complexA_Bi) = (complex.mulz(bi, ai, br, ar)); //A*B
        (int256 complexB_Ar, int256 complexB_Ai) = (complex.mulz(ai, bi, ar, br)); //B*A
        (int256 complexB_Cr, int256 complexB_Ci) = (complex.mulz(ci, bi, cr, br)); //B*C
        (int256 complexA_Cr, int256 complexA_Ci) = (complex.mulz(ci, ai, cr, ar)); //A*C
        (int256 complexAB_Cr, int256 complexAB_Ci) = (complex.mulz(ci, complexA_Bi, cr, complexA_Br)); //(AB)*C
        (int256 complexA_BCr, int256 complexA_BCi) = (complex.mulz(complexB_Ci, ai, complexB_Cr, ar)); //A*(BC)
        (int256 complexA__Br, int256 complexA__Bi) = (complex.addz(bi, ai, br, ar)); //A+B
        (int256 complexAB__Cr, int256 complexAB__Ci) = (complex.mulz(ci, complexA__Bi, cr, complexA__Br)); //(A+B)*C
        (int256 complexAC_BCr, int256 complexAC_BCi) =
            (complex.addz(complexB_Ci, complexA_Ci, complexB_Cr, complexA_Cr)); // AC+BC
        (int256 complexA_Ar, int256 complexA_Ai) = (complex.mulz(0, ai, 1, ar)); //A*1
        (int256 complexdAr,int256 complexdAi) = (complex.divz(ai*scale,0*scale,ar*scale,1*scale)); // 1/A
        (int256 complexinAr,int256 complexinAi)=(complex.mulz(complexdAi,ai,complexdAr,ar)); // (1/A)*A

        //Commutative A*B != B*A
        assertFalse(complexA_Br != complexB_Ar);
        assertFalse(complexA_Bi != complexB_Ai);
        //Associative (AB)C=A(BC)
        assertEq(complexAB_Cr, complexA_BCr);
        assertEq(complexAB_Ci, complexA_BCi);
        //Distributive (A+B)*C=AC+BC
        assertEq(complexAB__Cr, complexAC_BCr);
        assertEq(complexAB__Ci, complexAC_BCi);
        // Existance of additive identity A*1=A
        assertEq(complexA_Ar, ar);
        assertEq(complexA_Ai, ai);
        //Existance of additive inverse A*(1/A)= 1
        assertEq(complexinAi/scale,0);
        assertApproxEqAbs(complexinAr*10/scale,10,5);
    }

    // devision is basically and multiplication of complex numbers is tested above
    function testDivZFuzz(int256 ar,int256 ai,int256 br,int256 bi) public{
        vm.assume(ai!=0);
        vm.assume(bi!=0);
        vm.assume(ar!=0);
        vm.assume(br!=0);
        ai = bound(ai,-1e10,1e10);
        bi = bound(bi,-1e10,1e10);
        ar = bound(ar,-1e10,1e10);
        br = bound(br,-1e10,1e10);
        (int256 Nr,int256 Ni)=(complex.mulz(-bi,ai,br,ar));
        (int256 Dr,)=(complex.mulz(-bi,bi,br,br));
        int256 Rr= PRBMathSD59x18.div(Nr,Dr);
        int256 Ri= PRBMathSD59x18.div(Ni,Dr);
        (int256 Rhr,int256 Rhi)=(complex.divz(bi,ai,br,ar));
        assertEq(Rr,Rhr);
        assertEq(Ri,Rhi);
    }

    // function testCalc_RFuzz(int256 ar, int256 ai, int256 br, int256 bi, int256 k) public {
    //     ai = bound(ai, -1e9, 1e9);
    //     bi = bound(bi, -1e9, 1e9);
    //     ar = bound(ar, -1e9, 1e9);
    //     br = bound(br, -1e9, 1e9);
    //     k = bound(k, -1e9, 1e9);

    //     (int256 mag1r,) = (complex.mulz(-ai, ai, ar, ar)); // ar^2 + ai^2
    //     int256 mag1 = PRBMathSD59x18.sqrt(mag1r); // (ar^2+ai^2)^0.5
    //     uint256 R1 = (complex.calcR(ai, ar)); // magnitude(A)
    //     uint256 R2 = (complex.calcR(bi, br)); // magnitude(B)
    //     (int256 A_Br, int256 A_Bi) = (complex.addz(bi, ai, br, ai)); // A+B
    //     uint256 R3 = (complex.calcR(A_Bi, A_Br)); // magnitude(A+B)
    //     uint256 R4 = (complex.calcR(k * ai, k * ar)); // magnitude(k*A)
    //     uint256 magk = (complex.calcR(0, k));
    //     uint256 _R1 = (complex.calcR(-ai, ar));

    //     // Test by comparing
    //     assertEq(uint256(mag1) / 1e9, R1);

    //     // Test by property
    //     // mag(A+B)<=mag(A)+mag(B)
    //     assert(R3 <= (R1 + R2));
    //     // mag(kA)=kmag(A)
    //     assertEq(R4,(magk)*R1);
    //     // mag(A)=mag(A')
    //     assertEq(R1,_R1);
    // }

    
}

interface WRAPPER {
    function subz(int256, int256, int256, int256) external returns (int256, int256);

    function addz(int256, int256, int256, int256) external returns (int256, int256);

    function mulz(int256, int256, int256, int256) external returns (int256, int256);

    function divz(int256, int256, int256, int256) external returns (int256, int256);

    function calcR(int256, int256) external returns (uint256);

    function toPolar(int256, int256) external returns (int256, int256);

    function fromPolar(int256, int256) external returns (int256, int256);

    function p_atan2(int256, int256) external returns (int256);

    function atan1to1(int256) external returns (int256);

    function ln(int256, int256) external returns (int256, int256);

    function sqrt(int256, int256) external returns (int256, int256);

    function expZ(int256, int256) external returns (int256, int256);

    function pow(int256, int256, int256) external returns (int256, int256);
}
