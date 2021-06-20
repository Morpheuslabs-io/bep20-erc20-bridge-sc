// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./MITx.sol";

contract BSCETHSwap {

    address registeredERC20;
    address registeredBEP20;
    bytes32 public ethSwapInitTxHash;
    
    mapping(bytes32 => bool) public filledETHTx;
    mapping(address => bool) public whitelist;

    address payable public owner;
    uint256 public swapFee;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event SwapStarted(
        address indexed bep20Addr,
        address indexed erc20Addr,
        address indexed fromAddr,
        uint256 amount,
        uint256 feeAmount
    );

    event SwapFilled(
        address indexed bep20Addr,
        bytes32 indexed ethTxHash,
        address indexed toAddress,
        uint256 amount
    );

    constructor(uint256 _fee, bytes32 _ethSwapInitTxHash, address _erc20Addr, address _bep20Addr) {
        swapFee = _fee;
        owner = payable(msg.sender);
        // whitelist[owner] = true;

        registeredERC20 = _erc20Addr;
        registeredBEP20 = _bep20Addr;
        ethSwapInitTxHash = _ethSwapInitTxHash;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyWhitelist() {
        require(whitelist[msg.sender] == true, "Ownable: caller is not in the whitelist");
        _;
    }

    function addWhitelist(address user) public onlyOwner {
        whitelist[user] = true;
    }

    function removeWhitelist(address user) public onlyOwner {
        whitelist[user] = false;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function transferOwnershipOfToken(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        MITx(registeredBEP20).transferOwnership(newOwner);
    }

    /**
     * @dev Returns set minimum swap fee from BEP20 to ERC20
     */
    function setSwapFee(uint256 fee) external onlyOwner {
        swapFee = fee;
    }

    /**
     * @dev mint token on bsc by batch for eth transactions
     */
    function fillETH2BSCSwap(
        bytes32[] calldata ethTxHashArr,
        address[] calldata toAddressArr,
        uint256[] calldata amountArr
    ) external onlyWhitelist returns (bool) {
        require(ethTxHashArr.length == toAddressArr.length, "Input length");
        require(ethTxHashArr.length == amountArr.length, "Input length");
        
        for (uint256 i = 0; i < ethTxHashArr.length; i++) {
            require(!filledETHTx[ethTxHashArr[i]], "eth tx filled already");

            filledETHTx[ethTxHashArr[i]] = true;
            MITx(registeredBEP20).mintTo(amountArr[i], toAddressArr[i]);

            emit SwapFilled(
                registeredBEP20,
                ethTxHashArr[i],
                toAddressArr[i],
                amountArr[i]
            );
        }

        return true;
    }

    /**
     * @dev swap back token on BSC to ETH
     */
    function swapBSC2ETH(uint256 amount) external payable returns (bool) {
        require(msg.value == swapFee, "swap fee not equal");

        MITx(registeredBEP20).transferFrom(msg.sender, address(this), amount);
        MITx(registeredBEP20).burn(amount);
        if (msg.value != 0) {
            owner.transfer(msg.value);
        }

        emit SwapStarted(
            registeredBEP20,
            registeredERC20,
            msg.sender,
            amount,
            msg.value
        );
        return true;
    }
}
