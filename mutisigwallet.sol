// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MultiSigWallet{
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public numConfirmationRequired;
    mapping(uint=>mapping(address=>bool)) public isConfirmed;
    event SubmitTransaction(
        address indexed owner,
        uint indexed txIndex,
        address indexed to,
        uint value,
        bytes data
    );
    event ConfirmTransaction(
        address indexed owner,
        uint indexed txIndex
    );
    event ExecuteTransaction(
        address indexed owner,
        uint indexed txIndex
    );
    event RevokeConfirmation(
        address indexed owner,
        uint indexed txIndex
    );
    event Deposit(
        address indexed sender,
        uint amount,
        uint balance
    );
    struct Transaction{
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numberConfirmation;
    }
    Transaction[] public transactions;

    modifier onlyOwer(){
        require(isOwner[msg.sender],"not owner");
        _;
    }

    modifier txExist(uint _txIndex){
        require(_txIndex <transactions.length,"tx does not exist");
        _;
    }
    modifier notExecuted(uint _txIndex){
        require(!isConfirmed[_txIndex][msg.sender].executed,"tx does not exist");
        _;
    }
    modifier notConfirm(uint _txIndex){
        require(!isConfirmed[_txIndex][msg.sender],"tx already confirmed");
        _;
    }

    constructor (address[] memory _owners, uint _numConfirmationRequired){

        require(_owners.length > 0,"owners required");

        require(_numConfirmationRequired >0 && _numConfirmationRequired<=_owners.length,"invalid number of required confirmations");

        for(uint i = 0 ;i < _owners.length ;i++){
            address owner = _owners[i];

            require(owners[owner],"owner not unique");
            require(!isOwner[owner],"owner not unique");

            isOwner[owner] = true;

            owners.push(owner);
        }
       numConfirmationRequired = _numConfirmationRequired;
    }
    receive() external payable{
        emit Deposit(msg.sender,msg.value,address(this).balance);
    }

    function submitTransaction(address _to,uint _value,bytes memory _data) public onlyOwer{
        uint txIndex = transactions.length;
        transactions.push(
            transaction({
                to:_to,
                value:_value,
                data:_data,
                executed:false,
                numberConfirmation:0
            })
        );
        emit SubmitTransaction(msg.sender,txIndex,_to,_value,_data);
    }

    function confirmTransaction(uint _txIndex) public onlyOwer
    txExist(_txIndex)
    notExecuted(_txIndex)
    notConfirm(_txIndex){

        Transaction storage transaction=transactions[_txIndex];
        transaction.numberConfirmation +=1;
        isConfirmed[_txIndex][msg.sender] = true;
        emit ConfirmTransaction(msg.sender,_txIndex);
    }

    function executeTransaction(uint _txIndex) public onlyOwer
    txExist(_txIndex)
    notExecuted(_txIndex)
    {
            Transaction storage transaction = transactions[_txIndex];
            require(transaction.numberConfirmation >= numConfirmationRequired,"cannot execute tx");
            transaction.executed = true;
            (bool success,) = transaction.to.call(value, transaction.value)(transaction.data);
            require(success,"ts failed");
            emit ExecuteTransaction(msg.sender,_txIndex);

    }

    function revokeConfirmation(uint _txIndex) public onlyOwer
    txExist(_txIndex)
    notExecuted(_txIndex)
    {

         Transaction storage transaction = transactions[_txIndex];
         transaction.numberConfirmation -= 1;
         isConfirmed[_txIndex][msg.sender] = false;
         emit RevokeConfirmation(msg.sender,_txIndex);
    }
}