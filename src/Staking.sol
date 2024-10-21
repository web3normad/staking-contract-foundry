// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Coin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StakingPool {
    Coin public stakingToken;

    error TranferFailed();
    struct Pool {
        uint256 apy;
        uint256 maturityTime;
    }

    struct Stake {
        uint256 amount;
        uint256 timestamp;
        uint256 poolId;
        bool withdrawn;
    }

    Pool[] public pools;
    mapping(address => Stake[]) public stakes;

    uint256 public constant DAY = 86400;

    event Staked(address indexed user, uint256 poolId, uint256 amount);
    event Unstaked(
        address indexed user,
        uint256 poolId,
        uint256 amount,
        uint256 rewardAmount
    );
    event PoolAdded(uint256 poolId, uint256 apy, uint256 maturityTime);

    modifier validatePool(uint256 poolId) {
        require(poolId < pools.length, "Invalid pool ID");
        _;
    }

    constructor(address _stakingToken) {
        stakingToken = Coin(_stakingToken);
        addPool(2, DAY * 7); // Pool 1: 7 days, 2% APY
        addPool(25, DAY * 14); // Pool 2: 14 days, 2.5% APY
        addPool(3, DAY * 21); // Pool 3: 21 days, 3% APY
        addPool(35, DAY * 30); // Pool 4: 30 days, 3.5% APY
    }

    function stake(
        uint256 poolId,
        uint256 amount
    ) external validatePool(poolId) {
        require(amount > 0, "Amount must be greater than 0");

        uint256 contractBalanceBefore = stakingToken.balanceOf(address(this));
        stakingToken.transferFrom(msg.sender, address(this), amount);
        uint256 contractBalanceAfter = stakingToken.balanceOf(address(this));

        require(
            contractBalanceAfter == contractBalanceBefore + amount,
            "Token transfer failed"
        );

        stakes[msg.sender].push(
            Stake({
                amount: amount,
                timestamp: block.timestamp,
                poolId: poolId,
                withdrawn: false
            })
        );

        emit Staked(msg.sender, poolId, amount);
    }

    function unstake(uint256 poolId) external validatePool(poolId) {
        Stake storage userStake = stakes[msg.sender][poolId];
        require(userStake.amount > 0, "No stake found");
        require(!userStake.withdrawn, "Already withdrawn");

        uint256 rewardAmount = 0;

        if (
            block.timestamp >= userStake.timestamp + pools[poolId].maturityTime
        ) {
            uint256 timeStaked = block.timestamp - userStake.timestamp;
            rewardAmount = calculateReward(
                userStake.amount,
                pools[poolId].apy,
                timeStaked
            );
        }

        uint256 contractBalance = stakingToken.balanceOf(address(this));
        uint256 totalPayout = userStake.amount + rewardAmount;

        require(
            contractBalance >= totalPayout,
            "Insufficient contract balance"
        );

        userStake.withdrawn = true;
        stakingToken.transfer(msg.sender, userStake.amount);

        if (rewardAmount > 0) {
            stakingToken.transfer(msg.sender, rewardAmount);
        }

        emit Unstaked(msg.sender, poolId, userStake.amount, rewardAmount);
    }

    function calculateReward(
        uint256 amount,
        uint256 apy,
        uint256 timeStaked
    ) public pure returns (uint256) {
        return (amount * apy * timeStaked) / (100 * DAY * 365);
    }

    function getPoolCount() public view returns (uint256) {
        return pools.length;
    }
    
    function getPool(uint256 poolId) external view returns (uint256 apy, uint256 maturityTime) {
        require(poolId < pools.length, "Invalid pool ID");
        Pool memory pool = pools[poolId];
        return (pool.apy, pool.maturityTime);
    }

    function addPool(uint256 apy, uint256 maturityTime) internal {
        pools.push(Pool({apy: apy, maturityTime: maturityTime}));
        emit PoolAdded(pools.length - 1, apy, maturityTime);
    }

    function createPool(uint256 apy, uint256 maturityTime) external {
        addPool(apy, maturityTime);
    }

    function getUserStake(
        address user,
        uint256 poolId
    ) external view validatePool(poolId) returns (uint256) {
        Stake[] storage userStakeArray = stakes[user];
        require(poolId < userStakeArray.length, "No stake found for this pool");
        return userStakeArray[poolId].amount;
    }

    function getPoolBalance() external view returns (uint256) {
        return stakingToken.balanceOf(address(this));
    }

    function getStakes(address user) external view returns (Stake[] memory) {
        return stakes[user];
    }
}
