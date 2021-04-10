// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title 512位的大数处理 a*b/c，过程中a*b可能会溢出所以需要处理
/// @notice 256位的输入，在中间计算出现了大于256位的数,但是返回值又回到256位以内,为了避免中间过程的溢出精度损失,来个512的大数处理
/// @dev 防止有人恶意用中间过程溢出损失精度的方式作弊
library FullMath {
    /// @notice floor(a×b÷denominator) 如果返回值超过256位或者denominator=0则抛异常
    /// @param a 被乘数
    /// @param b 成数
    /// @param denominator 除数,分母
    /// @return result 256位的返回值
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 两个256位大数相乘最大是个512位数
        // Compute the product mod 2**256 and mod 2**256 - 1
        // 根据中国剩余定理(Chinese Remainder Theorem)计算
        // 512位数字存在两个256位的变量里:prod0,prod1
        // 大数计算 product = prod1 * 2**256 + prod0
        uint256 prod0; // 低位
        uint256 prod1; // 高位
        assembly {
            //因为mulmod计算a*b时不会损失精度,所以才能获得高位部分
            let mm := mulmod(a, b, not(0)) //not(0) = uint64(-1) = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))//lt():mm < prod0 ? 1 : 0
        }

        // 如果没有溢出,则直接相除就可以
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // 确保除完后不能溢出
        // 同时也确保 denominator > 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 用512位的大数去除denominator,目标要获得一个256位的数
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // 通过余数处理提高除法精度
        // Compute remainder using mulmod
        // 计算余数
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // 计算denominator的最小奇数除数
        // 神奇的计算方法,没找到理论支撑,只知道作用
        // twos计算后永远 >= 1.(奇数计算都是1,偶数是2的幂次方)
        uint256 twos = -denominator & denominator;
        // denominator除以2的最大幂
        // 如果是奇数计算前后denominator不变
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        // ^ 异或运算,异或后再异或等于本身 a=a^2^2
        uint256 inv = (3 * denominator) ^ 2;
        //接下来用牛顿迭代算法来提高精度(Newton-Raphson,precision)
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    // 精度计算有个基础理念是对我有利，避免被薅羊毛，因为四舍五入不能确定对谁有利，存在风险,基本不在合约中使用
    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @notice 向上取整,如果溢出或者除数为0抛异常
    /// @param a 被成数
    /// @param b 成数
    /// @param denominator 除数
    /// @return result 返回256位的数
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}
