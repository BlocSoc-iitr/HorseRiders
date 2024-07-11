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
        assertEq(r, 229729729729729729); // (17/74 = 0.229729729729729729..)
        assertEq(i, -121621621621621621); // (-9/74=-0.121621621621621621)
    }

    function testCalcR() public {
        uint256 r = complex.calcR(4 * scale, 4 * scale);
        assertEq(r, 5656854249492380195); // root(32)=5.656854249492380195
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
        (int256 complexA_Br, int256 complexA_Bi) = (complex.addz(bi, ai, br, ar)); //A+B
        (int256 complexB_Ar, int256 complexB_Ai) = (complex.addz(ai, bi, ar, br)); //B+A
        (int256 complexB_Cr, int256 complexB_Ci) = (complex.addz(ci, bi, cr, br)); //B+C

        //Commutative A + B = B + A
        assertEq(complexA_Br, complexB_Ar);
        assertEq(complexA_Bi, complexB_Ai);

        //Used same variables to avoid stacktoodeep error
        (complexA_Br, complexA_Bi) = (complex.addz(ci, complexA_Bi, cr, complexA_Br)); //(A+B)+C
        (complexB_Cr, complexB_Ci) = (complex.addz(complexB_Ci, ai, complexB_Cr, ar)); //A+(B+c)
        //Associative (A+B)+C = A+(B+C)
        assertEq(complexA_Br, complexB_Cr);
        assertEq(complexA_Bi, complexB_Ci);

        (complexA_Br, complexA_Bi) = (complex.addz(0, ai, 0, ar)); //A + 0
        (complexB_Cr, complexB_Ci) = (complex.addz(-(ai), ai, -(ar), ar)); //A + (-A)
        // Existance of additive identity A+0=A
        assertEq(complexA_Br, ar);
        assertEq(complexA_Bi, ai);
        //Existance of additive inverse A + (-A)=0
        assertEq(complexB_Cr, 0);
        assertEq(complexB_Ci, 0);
    }

    function testSubZFuzz(int256 bi, int256 ai, int256 ci, int256 br, int256 ar, int256 cr) public {
        //bounded input to avoid underflow or overflow
        vm.assume(ai != bi);
        vm.assume(bi != ci);
        vm.assume(ai != ci);
        vm.assume(ar != br);
        vm.assume(br != cr);
        vm.assume(ar != cr);
        vm.assume(bi != 0);
        vm.assume(ai != 0);
        vm.assume(ci != 0);
        vm.assume(ar != 0);
        vm.assume(br != 0);
        vm.assume(cr != 0);
        bi = bound(bi, -1e40, 1e40);
        ai = bound(ai, -1e40, 1e40);
        ci = bound(ci, -1e40, 1e40);
        br = bound(br, -1e40, 1e40);
        ar = bound(ar, -1e40, 1e40);
        cr = bound(cr, -1e40, 1e40);

        (int256 complexA_Br, int256 complexA_Bi) = (complex.subz(bi, ai, br, ar)); //A-B
        (int256 complexB_Ar, int256 complexB_Ai) = (complex.subz(ai, bi, ar, br)); //B-A
        (int256 complexB_Cr, int256 complexB_Ci) = (complex.subz(ci, bi, cr, br)); //B-C
        //Commutative A - B != B - A
        assertFalse(complexA_Br == complexB_Ar);
        assertFalse(complexA_Bi == complexB_Ai);

        (complexA_Br, complexA_Bi) = (complex.subz(ci, complexA_Bi, cr, complexA_Br)); //(A-B)-C
        (complexB_Ar, complexB_Ai) = (complex.subz(complexB_Ci, ai, complexB_Cr, ar)); //A-(B-c)
        //Associative (A-B)-C != A-(B-C)
        assertFalse(complexA_Br == complexB_Ar);
        assertFalse(complexA_Bi == complexB_Ai);

        (complexA_Br, complexA_Bi) = (complex.subz(0, ai, 0, ar)); //A - 0
        // Existance of additive identity A-0=A
        assertEq(complexA_Br, ar);
        assertEq(complexA_Bi, ai);
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
        //Commutative A*B = B*A
        assertEq(complexA_Br, complexB_Ar);
        assertEq(complexA_Bi, complexB_Ai);

        (complexA_Br, complexA_Bi) = (complex.mulz(ci, complexA_Bi, cr, complexA_Br)); //(AB)*C
        (complexB_Ar, complexB_Ai) = (complex.mulz(complexB_Ci, ai, complexB_Cr, ar)); //A*(BC)
        //Associative (AB)C=A(BC)
        assertEq(complexA_Br, complexB_Ar);
        assertEq(complexA_Bi, complexB_Ai);

        (complexA_Br, complexA_Bi) = (complex.addz(bi, ai, br, ar)); //A+B
        (complexA_Br, complexA_Bi) = (complex.mulz(ci, complexA_Bi, cr, complexA_Br)); //(A+B)*C
        (complexB_Ar, complexB_Ai) = (complex.addz(complexB_Ci, complexA_Ci, complexB_Cr, complexA_Cr)); // AC+BC
        //Distributive (A+B)*C=AC+BC
        assertEq(complexA_Br, complexB_Ar);
        assertEq(complexA_Bi, complexB_Ai);

        (complexA_Br, complexA_Bi) = (complex.mulz(0, ai, 1, ar)); //A*1
        // Existance of additive identity A*1=A
        assertEq(complexA_Br, ar);
        assertEq(complexA_Bi, ai);

        (complexA_Br, complexA_Bi) = (complex.divz(ai * scale, 0 * scale, ar * scale, 1 * scale)); // 1/A
        (complexA_Br, complexA_Bi) = (complex.mulz(complexA_Bi, ai, complexA_Br, ar)); // (1/A)*A
        //Existance of additive inverse A*(1/A)= 1
        assertEq(complexA_Bi / scale, 0);
        assertApproxEqAbs(complexA_Br * 10 / scale, 10, 5);
    }

    // devision is basically and multiplication of complex numbers is tested above
    function testDivZFuzz(int256 ar, int256 ai, int256 br, int256 bi) public {
        vm.assume(ai != 0);
        vm.assume(bi != 0);
        vm.assume(ar != 0);
        vm.assume(br != 0);
        ai = bound(ai, -1e10, 1e10);
        bi = bound(bi, -1e10, 1e10);
        ar = bound(ar, -1e10, 1e10);
        br = bound(br, -1e10, 1e10);
        (int256 Nr, int256 Ni) = (complex.mulz(-bi, ai, br, ar));
        (int256 Dr,) = (complex.mulz(-bi, bi, br, br));
        int256 Rr = PRBMathSD59x18.div(Nr, Dr);
        int256 Ri = PRBMathSD59x18.div(Ni, Dr);
        (int256 Rhr, int256 Rhi) = (complex.divz(bi, ai, br, ar));
        assertEq(Rr, Rhr);
        assertEq(Ri, Rhi);
    }

    function testCalc_RFuzz(int256 ar, int256 ai, int256 br, int256 bi, int256 k) public {
    ai = bound(ai, -1e9, 1e9);
    bi = bound(bi, -1e9, 1e9);
    ar = bound(ar, -1e9, 1e9);
    br = bound(br, -1e9, 1e9);
    k = bound(k, -1e8 , 1e8);

    //ar^2+ai^2 = magnitude(A)**2
    (int256 mag1r,) = (complex.mulz(-ai*scale, ai*scale, ar*scale, ar*scale)); // ar^2 + ai^2
    int256 R1 = (int256((complex.calcR(ai*scale, ar*scale)))**2); // magnitude(A)
    assertApproxEqAbs(mag1r/scale, R1/scale, 5e17);

   //mag(A) = mag(-A)
    mag1r = int256(complex.calcR(-ai*scale ,  ar*scale)**2);
    assertEq(mag1r/scale, R1/scale);

   //(mag(a))**2 = (k*mag(A))**2
    (mag1r , ) = (complex.mulz(-ai*scale, ai*scale, ar*scale, ar*scale)); // kA
     int256 R3 = (int256(complex.calcR((k*ai)*scale, (k*ar)*scale))**2); // magnitude(A)
    assertApproxEqAbs(((k**2)*(mag1r/scale)), R3/scale, 5e17);

   //mag(z1z2) = mag(z1)*mag(z2)
    (int256 ir , int256 mag1i) = complex.mulz(bi*scale, ai*scale, br*scale, ar*scale);
    R1 = (int256((complex.calcR((ai*scale), (ar*scale)))));
    int256 R2 = (int256(complex.calcR(bi*scale, br*scale))); // magnitude(B)
     R3 = (int256(complex.calcR((mag1i/scale) , (ir/scale))));
    assertApproxEqAbs(R3 , (R1*R2)/scale, 5e17); 


     //magnitude(A+B) <= magnitude(A) + magnitude(B)
    R3  = (int256(complex.calcR((bi+ai)*scale , (br + ar)*scale)));
    assert (R1 + R2 >= R3);

    }

     function testSqrtfuzz(int256 ar , int256 ai ) public {
        ai = bound(ai, -1e15 , 1e15);
        ar = bound(ar, -1e15 , 1e15);
    
        (int256 sqrt_ar , int256 sqrt_ai) = complex.sqrt(ai*scale , ar*scale);
        (int256 r , int256 i) = complex.mulz(sqrt_ai , sqrt_ai , sqrt_ar , sqrt_ar);
        r >= 0 ? r = r : r = -r;
        i >= 0 ? i = i : i = -i;
        ar >= 0 ? ar =  ar : ar = -ar;
        ai >= 0 ? ai =  ai : ai =  -ai;
        assertApproxEqAbs((r/(scale))  ,ar*scale, 5e17);
        assertApproxEqAbs((i/(scale)) , ai*scale , 5e17);
    }

//tan(tan-1x) = x

 function testAtan1to1Fuzz(int256 ar, int256 br) public {
        ar = bound(ar, 1e16, 1e18);
        br = bound(br, 1e16, 1e18);

        int256 r = complex.atan1to1(ar);
       assert(-157*1e16 <= r && r <= 157*1e16);

        int256 r1 = (Trigonometry.sin(uint256(r))*1e18)/Trigonometry.cos(uint256(r)) ;
        assertApproxEqAbs(ar , r1 , 5e15);

        ar = bound(ar , 1e15 , 1e16);
         r = complex.atan1to1(ar);
         r1 = (Trigonometry.sin(uint256(r))*1e18)/Trigonometry.cos(uint256(r)) ;
        assertApproxEqAbs(ar , r1 , 5e14);

        ar = bound(ar , 1e14, 1e15);
         r = complex.atan1to1(ar);
         r1 = (Trigonometry.sin(uint256(r))*1e18)/Trigonometry.cos(uint256(r)) ;
        assertApproxEqAbs(ar , r1 , 5e13);



    }


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
