//SDPX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20("Test Token", "TOKEN") {
    function mint() external {
        _mint(msg.sender, 1000 ether);
    }

    function mintTo(address _to) external {
        _mint(_to, 1000 ether);
    }
}
