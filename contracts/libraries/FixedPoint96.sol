// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.4.0;

/// @title FixedPoint96
/// @notice 定义一个96位数, see https://en.wikipedia.org/wiki/Q_(number_format)
/// @dev 在 SqrtPriceMath.sol 中用到
library FixedPoint96 {
    uint8 internal constant RESOLUTION = 96;
    uint256 internal constant Q96 = 0x1000000000000000000000000;
}
