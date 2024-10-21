// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    // State variable to store the contract owner's address
    address private _owner;

    // Event to notify when ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    // Modifier to restrict function access to only the owner
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    // Constructor to set the initial owner (deployer)
    constructor() {
        _transferOwnership(msg.sender);
    }

    // Function to get the current owner's address
    function owner() public view returns (address) {
        return _owner;
    }

    // Function to renounce ownership (leave the contract without an owner)
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    // Function to transfer ownership to a new owner
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    // Internal function to handle the ownership transfer
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
