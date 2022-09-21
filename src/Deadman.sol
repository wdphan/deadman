// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

/**
 * @title Deadman
 * @dev A beneficiary account
 **/

import { Vm } from 'forge-std/Vm.sol';
import { Deadman } from '/Users/williamphan/Desktop/Developer/deadman/src/Deadman.sol';
import { DSTest } from 'ds-test/test.sol';

abstract contract Deadman is DSTest {
    /// -----------------------------------
    /// -------- BASIC INFORMATION --------
    /// -----------------------------------

    /// @notice the account has closed/ended
    uint256 public accountClosed;

    /// @notice the time length of account
    uint256 public accountLength;

    /// @notice the min deposit in order to initialize account
    uint256 public minAmount;

    /// @notice the min protocol fees
    uint256 public fee;

    /// -----------------------------------
    /// ------- ACCOUNT INFORMATION -------
    /// -----------------------------------

    /// @notice the current owner of the account
    address public owner;

    /// @notice the backup owner of the account
    address public backup;

    /// @notice the account amount
    uint256 public liveAmount;

    enum State {
        inactive,
        live,
        ended
    }

    State public accountState;

    /// -----------------------------------
    /// ------------- EVENTS --------------
    /// -----------------------------------

    /// @notice An event emitted when someone redeems all ERC20 tokens
    event Claim(
        address indexed protocol,
        address indexed claimer,
        uint256 liveAmount
    );

    /// @notice An event emitted when someone pings the account
    event PingPlaced(address indexed owner, uint256 timestamp);

    /// --------------------------------
    /// -------- VIEW FUNCTIONS --------
    /// --------------------------------

    function currentOwner() public view returns (address) {
        return owner;
    }

    // retreives amount locked up in the current contract
    function retrieveAmount() public view returns (uint256) {
        return liveAmount;
    }

    function time() public view returns (uint256) {
        return accountLength;
    }

    /// --------------------------------
    /// -------- CORE FUNCTIONS --------
    /// --------------------------------

    // depositor/owner initializes the account
    function initialize(
        address _owner,
        address _backup,
        uint256 _minAmount,
        uint256 _liveAmount,
        uint256 _fee
    ) external {
        // set storage variables
        accountState = State.inactive;
        owner = _owner;
        backup = _backup;
        accountLength = 15 minutes;
        liveAmount = _liveAmount;
        fee = _fee;
        minAmount = _minAmount;

        _mint(_owner, _liveAmount);
    }

    // minimum deposit needed in order to initialize account
    function minDeposit(uint256 _minAmount) public pure {
        require(_minAmount >= 130000 ether, "Doesn't meet minimum deposit");
    }

    // updates the current owner of the locked up tokens
    function updateOwner(address _owner) external {
        require(msg.sender == owner, "You're not the owner");
        owner = _owner;
    }

    // sets the backup addresses, ultimately looped through
    function updateBackup(address _backup) external {
        require(msg.sender == owner, "You're not the owner!");
        backup = _backup;
    }

    // timer ends, auction ends, and tokens are sent to new owner
    function close() external {
        require(accountState == State.ended, "The account is still live");
        require(block.timestamp >= accountClosed, "The account is still live");

        accountState = State.ended;

        // transfer erc20 to backup because owner did not ping
        ERC20.transferFrom(address(this), backup, liveAmount);

        // emit the transfer event
        emit Claim(address(this), backup, liveAmount);
    }

    /// --------------------------------
    /// ------------ PING --------------
    /// --------------------------------

    // ping the account to notify owner is still alive - in replace of placing a bid
    function placePing() external payable {
        require(accountState == State.live, "Account is inactive");

        // If bid is within 15 minutes of auction end, extend auction
        if (accountLength - block.timestamp <= 15 minutes) {
            accountLength += 15 minutes;
        }

        emit PingPlaced(msg.sender, block.timestamp);
    }
}
