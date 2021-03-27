// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Math library for liquidity
/// @title 流动性计算库
library LiquidityMath {
    /// @notice Add a signed liquidity delta to liquidity and revert if it overflows or underflows
    /// @notice 增加流动性,负数表示减,防止溢出
    /// @param x The liquidity before change
    /// @param x 变化前流动性
    /// @param y The delta by which liquidity should be changed
    /// @param y 本次变化量,带符号
    /// @return z 变化后流动性
    function addDelta(uint128 x, int128 y) internal pure returns (uint128 z) {
        if (y < 0) {
            require((z = x - uint128(-y)) < x, 'LS');
        } else {
            require((z = x + uint128(y)) >= x, 'LA');
        }
    }
}
