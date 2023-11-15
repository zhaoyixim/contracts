// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./Pausable.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
contract UnityTernimal is Pausable,Ownable { 
    using SafeERC20 for IERC20;
    IERC20 private _usdt;
    address private _usdtAddr = address(0xDbf8Bf15bb3438b7410d8f009d652508ffA97C7B);
    constructor(){}
    event Deposit(address indexed sender,uint amount,uint balance);   
    event WhoPayWhoHowMuch(address indexed senderaddress,address indexed receiveaddress,uint amount);

    function safeTransUSDTOut(address to, uint256 amount) public returns (bool){
        _usdt = IERC20(_usdtAddr);
        _usdt.safeTransfer(to, amount);
        emit WhoPayWhoHowMuch(msg.sender,to,amount);
        return true;
    }
    function safeTransUSDTFromOut(address from,address to,uint256 amount) public returns (bool){
        _usdt = IERC20(_usdtAddr);
        _usdt.safeTransferFrom(from,to, amount);
        emit WhoPayWhoHowMuch(from,to,amount);
        return true;
    } 
    receive() external payable{
        emit Deposit(msg.sender,msg.value,address(this).balance);
    }  
    fallback() external payable {} 
    function getAddressAndBalance(address _address) public view returns(uint){
        return _address.balance;
    }    
    function getContractAddress() public view returns(address){
        return address(this);
    }
    function getContractBalance() public view returns(uint){       
        return address(this).balance;
    }  
    function getOwner() public view returns(address){
        return owner();
    }
    function getOwnerBalance() public view returns(uint){         
        return msg.sender.balance;
    }  
    function destroyContact() public onlyOwner{
        address _owner = owner();       
        _usdt = IERC20(_usdtAddr);
        _usdt.transfer(_owner,_usdt.balanceOf(address(this)));
        selfdestruct(payable(_owner));
    }
    function pause() public onlyOwner {
        _pause();
    }
    function unpause() public onlyOwner {
        _unpause();
    }
}