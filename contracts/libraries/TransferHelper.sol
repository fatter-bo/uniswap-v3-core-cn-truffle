// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '../interfaces/IERC20Minimal.sol';

/// @title TransferHelper
/// ERC20转账
/// @notice Contains helper methods for interacting with ERC20 tokens that do not consistently return true/false
/// 不带返回值
library TransferHelper {
    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Calls transfer on token contract, errors with TF if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            //这里的语法对于跨合约交互应该是个通用方案
            token.call(abi.encodeWithSelector(IERC20Minimal.transfer.selector, to, value));
        //这里不太理解,是call永远返回还是IERC20Minimal.transfer的返回值呢?
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TF');
    }
}
