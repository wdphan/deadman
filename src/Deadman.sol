// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

/**
 * @title Deadman
 * @dev A beneficiary account
 **/

import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

contract Deadman is ERC20Upgradeable {
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

    constructor(address _owner) {
        _owner = address(this);
        accountState = State.live;
    }

    /// -----------------------------------
    /// ------------- EVENTS --------------
    /// -----------------------------------

    /// @notice An event emitted when someone redeems all ERC20 tokens
    event Claim(
        address indexed protocol,
        address indexed claimer,
        uint256 liveAmount
    );

    // @notice An event emitted when someone pings the account
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

    // --------------------------------
    // -------- CORE FUNCTIONS --------
    // --------------------------------

    // depositor/owner initializes the account
    function initialize(
        address _backup,
        uint256 _minAmount,
        uint256 _liveAmount,
        string memory _name,
        string memory _symbol
    ) external {
        // initialize inherited contracts
        __ERC20_init(_name, _symbol);
        // set storage variables
        backup = _backup;
        accountLength = 15 minutes;
        liveAmount = _liveAmount;
        minAmount = _minAmount;
    }

    // deposits tokens into the protocol
    function deposit(uint256 depositAmount) public payable {
        require(msg.value == depositAmount);
        require(
            msg.value >= 1000000000000000000 wei,
            "does not meet minimum deposit!"
        );
    }

    //updates the current owner of the locked up tokens
    function updateOwner(address _owner) external {
        require(msg.sender == owner, "You're not the owner");
        owner = _owner;
    }

    //sets the backup addresses, ultimately looped through
    function updateBackup(address _backup) external {
        require(msg.sender == owner, "You're not the owner!");
        backup = _backup;
    }

    // timer ends, auction ends, and tokens are sent to new owner
    function close(uint256 amount) external {
        require(accountState == State.ended, "The account is still live");
        require(block.timestamp >= accountClosed, "The account is still live");
        require(
            amount >= 1000000000000000000 wei,
            "account can't withdraw - add more funds"
        );

        accountState = State.ended;

        // transfer erc20 to backup because owner did not ping
        ERC20Upgradeable.transferFrom(address(this), backup, liveAmount);

        // emit the transfer event
        emit Claim(address(this), backup, liveAmount);
    }

    // --------------------------------
    // ------------ PING --------------
    // --------------------------------

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
