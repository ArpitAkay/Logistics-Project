// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Types.sol";
import "./Events.sol";
import "./Errors.sol";

contract GeekToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
    uint256 internal maxSupply = 10000000 * (10 ** decimals());     // 1 crore = 10 million
    address serviceRequestAddr = address(0);

    constructor(address initialOwner)
        ERC20("GeekToken", "GTK")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 2500000 * 10 ** decimals());  // 25 lakh = 2.5 million
    }

    modifier isServiceRequestContract(address _addr) {
        if(serviceRequestAddr != _addr) {
            revert Errors.AccessDenied({ from: _addr, message: "You are not allowed to call this method"});
        }
        _;
    }

    function updateServiceRequestAddr(address _addr) external onlyOwner {
        serviceRequestAddr = _addr;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply() + amount <= maxSupply, "We sold out");
        _mint(to, amount);
    }

    // The following functions are overrides required by Solidity.

    function _update(address from, address to, uint256 value)
        internal
        override(ERC20, ERC20Pausable)
    {
        super._update(from, to, value);
    }

    function tokenReward(uint256 cargoInsuredValue, Types.Acceptance acceptance) internal view returns (uint256) {
        uint256 _reward = 0;
        uint256 _totalSupply = totalSupply();
        if(_totalSupply >= (maxSupply * 25 / 100) && _totalSupply < (maxSupply * 50 / 100)) {
            if(acceptance == Types.Acceptance.CONDITIONAL)
                _reward = 2 * cargoInsuredValue * (10 ** decimals()) / 100;
            else
                _reward = 1 * cargoInsuredValue * (10 ** decimals()) / 100;
        } else if(_totalSupply >= (maxSupply * 50 / 100) && _totalSupply < (maxSupply * 75 / 100)) {
             if(acceptance == Types.Acceptance.CONDITIONAL)
                _reward = 1 * cargoInsuredValue * (10 ** decimals()) / 100;
            else
                _reward = 5 * cargoInsuredValue * (10 ** decimals()) / 1000;
        } else if(_totalSupply >= (maxSupply * 75 / 100) && _totalSupply < (maxSupply * 95 / 100)) {
             if(acceptance == Types.Acceptance.CONDITIONAL)
                _reward = 5 * cargoInsuredValue * (10 ** decimals()) / 1000;
            else
                _reward = 25 * cargoInsuredValue * (10 ** decimals()) / 10000;
        } else {
            _reward = 0;
        }

        return _reward;
    }

    function transferTokens(address to, uint256 cargoInsurableValue, Types.Acceptance acceptance) isServiceRequestContract(msg.sender) external {
        uint256 tokensToReward = tokenReward(cargoInsurableValue, acceptance);

        address ownerAddr = owner();

        if(balanceOf(ownerAddr) >= tokensToReward)
            _transfer(owner(), to, tokensToReward);
        else
            revert Errors.NotSufficientFunds({ account: ownerAddr, message: "Not sufficient funds"});

        emit Events.TransferedTokens(address(this), to, tokensToReward);
    }
}
