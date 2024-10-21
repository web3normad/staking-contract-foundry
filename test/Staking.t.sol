// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;


import "../src/Staking.sol";
import "../src/Coin.sol";
import "forge-std/Test.sol";



contract StakingPoolTest is Test {

    StakingPool stakingPool;
    Coin token;

    uint256 constant ONE_ETHER = 1 ether;


 function setUp() public {
    token = new Coin(address(this));
    stakingPool = new StakingPool(address(token));
    token.mint(address(stakingPool), 100000 ether);
    token.mint(address(this), 1000 ether);
}


      function testStake() public {
        token.approve(address(stakingPool), 100 * ONE_ETHER);
        stakingPool.stake(0, 100 * ONE_ETHER);
        assertEq(token.balanceOf(address(this)), 900 * ONE_ETHER);
    }

 function testUnstake() public {
    token.approve(address(stakingPool), 100 * ONE_ETHER);
    stakingPool.stake(0, 100 * ONE_ETHER);

    vm.warp(block.timestamp + 8 days);

    uint256 expectedReward = stakingPool.calculateReward(
        100 * ONE_ETHER,
        2,     
        8 days 
    );
    uint256 expectedTotal = 100 * ONE_ETHER + expectedReward;

    stakingPool.unstake(0);
    uint256 actualBalance = token.balanceOf(address(this));

    console.log("Expected Total Balance: ", expectedTotal);
    console.log("Actual Balance after Unstake: ", actualBalance);

    assertEq(actualBalance, expectedTotal);
}



    function testCreatePool() public {
    uint256 oldPoolCount = stakingPool.getPoolCount();

    stakingPool.createPool(20, 30 days);
    uint256 newPoolCount = stakingPool.getPoolCount();
    assertEq(newPoolCount, oldPoolCount + 1);

    (uint256 apy, uint256 maturityTime) = stakingPool.getPool(newPoolCount - 1);
    assertEq(apy, 20);
    assertEq(maturityTime, 30 days);
}

    function testCalculateReward() public {
        token.approve(address(stakingPool), 100 * ONE_ETHER);
        stakingPool.stake(0, 100 * ONE_ETHER);

        vm.warp(block.timestamp + 7 days);

        uint256 expectedReward = (100 * ONE_ETHER * 2 * 7 days) / (100 * 86400 * 365);
        uint256 poolReward = stakingPool.calculateReward(100 * ONE_ETHER, 2, 7 days);

        assertEq(poolReward, expectedReward);
    }

    function testGetStakes() public {
        token.approve(address(stakingPool), 100 * ONE_ETHER);
        stakingPool.stake(0, 100 * ONE_ETHER);

        StakingPool.Stake[] memory userStakes = stakingPool.getStakes(address(this));

        assertEq(userStakes.length, 1);
        assertEq(userStakes[0].amount, 100 * ONE_ETHER);
        assertEq(userStakes[0].withdrawn, false); 
    }

}