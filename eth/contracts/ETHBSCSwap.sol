// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.3;

import "./IERC20.sol";

contract ETHBSCSwap {

    mapping(bytes32 => bool) public filledBSCTx;

    // mapping(address => bool) private whitelist;
    address registeredERC20;
    address payable public owner;
    address payable public vaultWallet;
    uint256 public swapFee;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event SwapStarted(
        address indexed erc20Addr,
        address indexed fromAddr,
        uint256 amount,
        uint256 feeAmount
    );
    event SwapFilled(
        address indexed erc20Addr,
        bytes32 indexed bscTxHash,
        address indexed toAddress,
        uint256 amount
    );

    constructor(
        uint256 fee,
        address erc20Addr,
        address payable ownerAddr,
        address payable vaultWalletAddr
    ) {
        swapFee = fee;
        owner = ownerAddr;
        vaultWallet = vaultWalletAddr;
        registeredERC20 = erc20Addr;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Returns set minimum swap fee from ERC20 to BEP20
     */
    function setSwapFee(uint256 fee) external onlyOwner {
        swapFee = fee;
    }

    /**
     * Transfer token from hot wallet to user wallets when user swap back from BSC to ETH
     */
    function fillBSC2ETHSwap(
        bytes32[] calldata bscTxHashArr,
        address[] calldata toAddressArr,
        uint256[] calldata amountArr
    ) external returns (bool) {
        require(bscTxHashArr.length == toAddressArr.length, "Input length");
        require(bscTxHashArr.length == amountArr.length, "Input length");

        for (uint256 i = 0; i < bscTxHashArr.length; i++) {
            require(!filledBSCTx[bscTxHashArr[i]], "bsc tx filled already");

            filledBSCTx[bscTxHashArr[i]] = true;
            require(
                IERC20(registeredERC20).transferFrom(
                    msg.sender,
                    toAddressArr[i],
                    amountArr[i]
                ),
                "Token transfer fail"
            );

            emit SwapFilled(
                registeredERC20,
                bscTxHashArr[i],
                toAddressArr[i],
                amountArr[i]
            );
        }

        return true;
    }

    /**
     * Swap token from ETH to BSC
     */
    function swapETH2BSC(uint256 amount) external payable returns (bool) {
        require(msg.value == swapFee, "swap fee not equal");

        require(
            IERC20(registeredERC20).transferFrom(
                msg.sender,
                vaultWallet,
                amount
            ),
            "Token transfer fail"
        );
        if (msg.value != 0) {
            vaultWallet.transfer(msg.value);
        }

        emit SwapStarted(registeredERC20, msg.sender, amount, msg.value);
        return true;
    }
}
