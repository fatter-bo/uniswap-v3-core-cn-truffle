// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;

import '../libraries/TickMath.sol';

contract TickMathTest {
    mapping(uint256=>uint256) public map;
    function getSqrtRatioAtTick(int24 tick) external pure returns (uint160) {
        return TickMath.getSqrtRatioAtTick(tick);
    }

    function getGasCostOfGetSqrtRatioAtTick(int24 tick) external view returns (uint256) {
        uint256 gasBefore = gasleft();
        TickMath.getSqrtRatioAtTick(tick);
        return gasBefore - gasleft();
    }

    function getTickAtSqrtRatio(uint160 sqrtPriceX96) external pure returns (int24) {
        return TickMath.getTickAtSqrtRatio(sqrtPriceX96);
    }

    function getGasCostOfGetTickAtSqrtRatio(uint160 sqrtPriceX96) external view returns (uint256) {
        uint256 gasBefore = gasleft();
        TickMath.getTickAtSqrtRatio(sqrtPriceX96);
        return gasBefore - gasleft();
    }

    function MIN_SQRT_RATIO() external pure returns (uint160) {
        return TickMath.MIN_SQRT_RATIO;
    }

    function MAX_SQRT_RATIO() external pure returns (uint160) {
        return TickMath.MAX_SQRT_RATIO;
    }
    function destroy() public {
        selfdestruct(msg.sender);
    }
    function add() public {
        for(uint256 i=0;i<10;i++){
            map[i+2**112]=i+2*112;
        }
    }
    event EventDel(uint256 indexed k,uint256 v,uint256 v1);
    function del() public {
        for(uint256 i=0;i<10;i++){
            emit EventDel(i,i+1,i+2);
            delete map[i+2**112];
        }
            emit EventDel(1,1,1);
    }
    function get() public view returns(uint256){
        return map[1+2**112];
    }
    function constuct() public {
        for(uint256 i=0;i<1000000000;i++){
            map[i+2**112]=i+2**112;
        }
    }
}
