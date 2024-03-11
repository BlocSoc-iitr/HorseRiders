// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/complexMath/Complex.sol";

contract ComplexTest is Test {
    WRAPPER public complex;
    int256 scale = 1e18;
    int256 scale2 = 1e19;
    Num_Complex public num_complex;

    function setUp() public {
        complex = WRAPPER(HuffDeployer.deploy("ComplexHuff/WRAPPER"));
        num_complex = new Num_Complex();
    }

    function testSubZ() public {
        (int256 r, int256 i) = complex.subz(
            4 * scale,
            5 * scale,
            8 * scale,
            11 * scale
        );
        assertEq(r / scale, 3);
        assertEq(i / scale, 1);
    }

    function testAddZ() public {
        (int256 r, int256 i) = complex.addz(
            2 * scale,
            3 * scale,
            4 * scale,
            5 * scale
        );
        assertEq(r / scale, 9);
        assertEq(i / scale, 5);
    }

    function testMulZ() public {
        (int256 r, int256 i) = complex.mulz(
            2 * scale,
            3 * scale,
            4 * scale,
            5 * scale
        );
        assertEq((r / scale) / scale, 14);
        assertEq((i / scale) / scale, 22);
    }

    function testDivZ() public {
        (int256 r, int256 i) = complex.divz(
            7 * scale,
            1 * scale,
            5 * scale,
            2 * scale
        );
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
        (int256 r, int256 i) = complex.expZ(92729522*1e10 , 1);
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

    function testAddZFuzz(int256 bi, int256 ai, int256 br, int256 ar) public {
        //bounded input to avoid underflow or overflow
        bi = bound(bi, -1e40, 1e40);
        ai = bound(ai, -1e40, 1e40);
        br = bound(br, -1e40, 1e40);
        ar = bound(ar, -1e40, 1e40);
        (int256 r, int256 i) = complex.addz(bi, ai, br, ar);
        Num_Complex.Complex memory complexA = Num_Complex.Complex(ar, ai);
        Num_Complex.Complex memory complexB = Num_Complex.Complex(br, bi);
        int256 resultR = num_complex.add(complexA, complexB).re;
        int256 resultI = num_complex.add(complexA, complexB).im;

        assertEq(resultR, r);
        assertEq(resultI, i);
    }

    function testSubZFuzz(int256 bi, int256 ai, int256 br, int256 ar) public {
        //bounded input to avoid underflow or overflow
        bi = bound(bi, -1e40, 1e40);
        ai = bound(ai, -1e40, 1e40);
        br = bound(br, -1e40, 1e40);
        ar = bound(ar, -1e40, 1e40);
        (int256 r, int256 i) = complex.subz(bi, ai, br, ar);
        Num_Complex.Complex memory complexA = Num_Complex.Complex(ar, ai);
        Num_Complex.Complex memory complexB = Num_Complex.Complex(br, bi);
        int256 resultR = num_complex.sub(complexA, complexB).re;
        int256 resultI = num_complex.sub(complexA, complexB).im;

        assertEq(resultR, r);
        assertEq(resultI, i);
    }

    function testMulZFuzz(int256 bi, int256 ai, int256 br, int256 ar) public {
        //bounded input to avoid underflow or overflow
        bi = bound(bi, -1e30, 1e30);
        ai = bound(ai, -1e30, 1e30);
        br = bound(br, -1e30, 1e30);
        ar = bound(ar, -1e30, 1e30);
        (int256 r, int256 i) = complex.mulz(bi, ai, br, ar);
        Num_Complex.Complex memory complexA = Num_Complex.Complex(ar, ai);
        Num_Complex.Complex memory complexB = Num_Complex.Complex(br, bi);
        int256 resultR = num_complex.mul(complexA, complexB).re;
        int256 resultI = num_complex.mul(complexA, complexB).im;
        assertEq(resultR, r);
        assertEq(resultI, i);
    }

    function testDivZFuzz(int256 bi, int256 ai, int256 br, int256 ar) public {
        //bounded input to avoid underflow or overflow
        vm.assume(bi != 0);
        vm.assume(ai != 0);
        vm.assume(br != 0);
        vm.assume(ar != 0);
        bi = bound(bi, -1e10, 1e10);
        ai = bound(ai, -1e10, 1e10);
        br = bound(br, -1e10, 1e10);
        ar = bound(ar, -1e10, 1e10);

        (int256 r, int256 i) = complex.divz(bi, ai, br, ar);
        Num_Complex.Complex memory complexA = Num_Complex.Complex(ar, ai);
        Num_Complex.Complex memory complexB = Num_Complex.Complex(br, bi);
        int256 resultR = num_complex.div(complexA, complexB).re;
        int256 resultI = num_complex.div(complexA, complexB).im;

        assertEq(resultR, r);
        assertEq(resultI, i);
    }

    function testCalcRFuzz(int256 a, int256 b) public {
        a = bound(a, -1e20, 1e20);
        b = bound(a, -1e20, 1e20);

        uint256 rH = complex.calcR(a * scale, b * scale);
        uint256 rS = uint(num_complex.r2(a * scale, b * scale));
        assertEq(rH / uint(scale), rS / uint(scale));
    }

        function testFromPolarFuzz(int256 r, int256 T) public {
        vm.assume(r !=0);

        r = bound(r, -1e20, 1e20);
        T = bound(T, -1e20, 1e20);
        (int256 rH, int256 iH) = complex.fromPolar(r * scale, T * 1e10);
        Num_Complex.Complex memory complexA = num_complex.fromPolar(r * scale, T * 1e10);
        (int256 rS, int256 iS) = num_complex.unwrap(complexA);

        assertEq(rH, rS);
        assertEq(iH, iS);

    }

    function testAtan1to1Fuzz(int256 r) public {
        r = bound(r, -1e10, 1e10);
        int256 rH = complex.atan1to1(r* 1e17);
        int256 rS = num_complex.atan1to1(r*1e17);
        assertEq((rH * 100) / scale, (rS*100)/scale);
    }

    // failing fuzz test due to Topolar
    
    // function testToPolarFuzz(int256 ar, int256 ai) public {
    //     vm.assume(ar !=0);
    //     vm.assume(ai !=0);
    //     ar = bound(ar, -1e20, 1e20);
    //     ai = bound(ai, -1e20, 1e20);
    //     (int256 rH, int256 tH) = complex.toPolar(ar, ai);
    //     Num_Complex.Complex memory complexA = Num_Complex.Complex(ar, ai);
    //     (int256 rS, int256 tS) = num_complex.toPolar(complexA);
    //     assertApproxEqAbs(rS ,rH ,10);
    //     assertEq(tH , tS);
    // }

    // function testSqrtFuzz(int256 ar, int256 ai) public {
    //     vm.assume(ar != 0);
    //     vm.assume(ai != 0);
    //     ar = bound(ar, -1e20, 1e20);
    //     ai = bound(ai, -1e20, 1e20);
    //     (int256 r, int256 i) = complex.sqrt(ai, ar);
    //     Num_Complex.Complex memory complexA = Num_Complex.Complex(
    //         ar,
    //         ai
    //     );
    //     int256 resultR = num_complex.sqrt(complexA).re;
    //     int256 resultI = num_complex.sqrt(complexA).im;
    //     assertEq(r / scale, resultR / (scale));
    //     assertEq(i, resultI );
    // }

    // function testAtan2() public {
    //     int256 r = complex.p_atan2(4 * scale, 3 * scale);
    //     int256 rS = num_complex.p_atan2(4 * scale, 3 * scale);
    //     assertEq((rS * 100) / scale, 0);
    //     assertEq((r * 100) / scale, 0);
    // }

    //  function testLnZFuzz(int256 ar, int256 ai) public {
    //     vm.assume(ar != 0);
    //     vm.assume(ai != 0);
    //     (int256 r, int256 i) = complex.ln(ar * scale, ar * scale);
    //     Num_Complex.Complex memory complexA = Num_Complex.Complex(ar*scale,ai*scale);
    //     (int256 rS, int256 iS) = num_complex.unwrap(num_complex.ln(complexA));
    //     assertEq((r * 100) / scale,(rS * 100) / scale ); // ln(50) = 3.912..
    //     assertEq((i * 100) / scale, (iS * 100) / scale);
    // }

    // function testExpZFuzz(int256 ar, int256 ai) public {
    //     (int256 rH, int256 iH) = complex.expZ(ar , ai);
    //     Num_Complex.Complex memory complexA =Num_Complex.Complex(ar,ai);
    //     (int256 rS, int256 iS) = num_complex.unwrap(num_complex.exp(complexA));
    //     assertEq(rS ,rH);
    //     assertEq(iS,iH);
    // }

    
    // function testPowZ(int256 p, int256 ai, int256 ar) public {
    //     (int256 rH, int256 iH) = complex.pow(p, ai * scale, ar * scale);
    //     Num_Complex.Complex memory complexA =Num_Complex.Complex(ar*scale,ai*scale);
    //     (int256 rS, int256 iS) = num_complex.unwrap(num_complex.pow(complexA,p));
    //     assertEq(rH,rS );
    //     assertEq(iH,iS );
    // }


     

     
}

interface WRAPPER {
    function subz(
        int256,
        int256,
        int256,
        int256
    ) external returns (int256, int256);

    function addz(
        int256,
        int256,
        int256,
        int256
    ) external returns (int256, int256);

    function mulz(
        int256,
        int256,
        int256,
        int256
    ) external returns (int256, int256);

    function divz(
        int256,
        int256,
        int256,
        int256
    ) external returns (int256, int256);

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
