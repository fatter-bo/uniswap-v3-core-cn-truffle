// SPDX-License-Identifier: BUSL-1.1
pragma solidity =0.7.6;

/// @title Prevents delegatecall to a contract
/// @title 限制一个合约只能有创建者自己调用的基类
/// @notice Base contract that provides a modifier for preventing delegatecall to methods in a child contract
abstract contract NoDelegateCall {
    /// @dev The original address of this contract
    /// @dev 合约创建地址
    address private immutable original;

    constructor() {
        // Immutables are computed in the init code of the contract, and then inlined into the deployed bytecode.
        // 初始化时写入,不可变
        // In other words, this variable won't change when it's checked at runtime.
        // 运行时不可再变
        original = address(this);
    }

    /// @dev Private method is used instead of inlining into modifier because modifiers are copied into each method,
    /// @dev 用个私有函数,然后用modifier调用,可以防止modifier将函数内容copy到每个用到modifier的函数里
    ///     and the use of immutable means the address bytes are copied in every place the modifier is used.
    function checkNotDelegateCall() private view {
        require(address(this) == original);
    }

    /// @notice Prevents delegatecall into the modified method
    /// 防代理调用修饰符
    modifier noDelegateCall() {
        checkNotDelegateCall();
        _;
    }
}
