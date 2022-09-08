// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


interface IERC20 { 
    function transferFrom(
        address from,
        address to,
        uint256 amountoftoken
    ) external returns(bool);

    function transfer(address to, uint256 amount) external returns (bool) ;
    function balanceOf(address account) external returns (uint256);
}

contract Lending_Borrowing{
    address owner;
    IERC20 StableTokenaddress;
    IERC20  othertokenAddress;

/// @dev A contract that lends and borrows out 
/// @dev users can come borrow with a colateral and they will be given the smart contract token(stablecoin) 
/// @dev you can deposit ether and get a smart contract token(stablecoin)
/// @dev you can deposit a token and get a smart contract token(stablecoin)
/// @dev you can deposit a token and get eth

    struct UsersDetails {
        uint depositedOthers;
        uint  loanedStable;
        uint depositeEth; 
        bool deposited;
    }

    ////////////////////////////////////CONSTRUCTOR///////////////////////////////////////////////
        constructor(IERC20 _StableTokenaddress, IERC20 _otherTokenAddress ){
        StableTokenaddress = _StableTokenaddress;
        othertokenAddress  = _otherTokenAddress;
        owner = msg.sender;
    }

    //////////////////////////////CUSTOM ERRORS////////////////////////////////////////////
    
    /// zero token not allowed
    error Zerotoken();
    /// complete the loaned amount
    error NotComplete();

    /////////////////////////////////////EVENTS/////////////////////////////////////////

    event deposited(address indexed depositor, uint amount , IERC20 indexed contractAddress);
    event returned(address indexed depositor, uint amount);
    
    mapping(address => UsersDetails) allUserDetails;

    /// @param _amountofOthers amount of other tokens to be deposited
    function depositeEthForStable(uint _amountofOthers) external{
        UsersDetails storage _UsersDetails = allUserDetails[msg.sender];
        require(_UsersDetails.deposited == false, "resolve others");
        if(_amountofOthers < 0){
            revert Zerotoken();
        }
        bool sentOthers = othertokenAddress.transferFrom(msg.sender, address(this), _amountofOthers);
        require(sentOthers, "failed");
        _UsersDetails.depositedOthers = _amountofOthers;
        bool sentStable = StableTokenaddress.transfer(msg.sender, _amountofOthers);
        require(sentStable, "failed");
        _UsersDetails.loanedStable = _amountofOthers;
        _UsersDetails.deposited = true;
        emit deposited(msg.sender,_amountofOthers,othertokenAddress);
    }

    /// @param amoutOfStable amount of other tokens to be returned
    function returnStableForEth(uint amoutOfStable) external{
        UsersDetails storage _UsersDetails = allUserDetails[msg.sender];
        require(_UsersDetails.deposited == true, "didnt deposite");
        if(amoutOfStable < 0){
            revert Zerotoken();
        }
        uint loaned =_UsersDetails.loanedStable;
        if(amoutOfStable < loaned){
            revert NotComplete();
        }
        bool sent = StableTokenaddress.transferFrom(msg.sender, address(this), amoutOfStable);
        require(sent, "failed");
        uint received =  _UsersDetails.depositedOthers;
        bool sentother = StableTokenaddress.transfer(msg.sender, received);
        require(sentother, "failed");
        _UsersDetails.deposited = false;
        emit returned(msg.sender, amoutOfStable);
    }

    function depositeOtherEthForStable() payable  external{
        UsersDetails storage _UsersDetails = allUserDetails[msg.sender];
        require(_UsersDetails.deposited == false, "resolve others");
        if(msg.value < 0){
            revert Zerotoken();
        }
        _UsersDetails.depositeEth = msg.value;
        uint Stable = msg.value /2;
        bool sentStable = StableTokenaddress.transfer(msg.sender, Stable);
        require(sentStable, "failed");
        _UsersDetails.loanedStable = Stable;
        _UsersDetails.deposited = true;
        emit deposited(msg.sender,msg.value,othertokenAddress);
    }
    
    /// @param amoutOfStable amount of other tokens to be returned
    function returnStableForOtherEth(uint amoutOfStable) external{
        UsersDetails storage _UsersDetails = allUserDetails[msg.sender];
        require(_UsersDetails.deposited == true, "didnt deposite");
        if(amoutOfStable < 0){
            revert Zerotoken();
        }
        uint loaned =_UsersDetails.loanedStable;
        if(amoutOfStable < loaned){
            revert NotComplete();
        }
        bool sent = StableTokenaddress.transferFrom(msg.sender, address(this), amoutOfStable);
        require(sent, "failed");
        uint received =  _UsersDetails.depositeEth;
        _UsersDetails.depositeEth = 0;
        (bool sents,) = payable(msg.sender).call{value:received}("");
        require(sents, "failed");
        _UsersDetails.deposited = false;
        emit returned(msg.sender, amoutOfStable);
    }
}