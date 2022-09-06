// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
 
/// @dev A contract that lends and borrows out 
/// @dev users can come borrow with a colateral and they will be given the smart contract token(stablecoin) 
/// @dev you can deposit ether and get a smart contract token(stablecoin)
/// @dev you can deposit a token and get a smart contract token(stablecoin)
/// @dev you can deposit a token and get eth

interface IERC20 { 
    function transferFrom(
        address from,
        address to,
        uint256 amountoftoken
    ) external returns(bool);

    function transfer(address to, uint256 amount) external returns (bool) ;
    function balanceOf(address account) external returns (uint256);
} 

contract Lending_Saving{
    IERC20 StableTokenaddress;
    IERC20 otherTokenAddress;
    address owner;

    constructor(IERC20 _StableTokenaddress, IERC20 _otherTokenAddress ){
        StableTokenaddress = _StableTokenaddress;
        otherTokenAddress  = _otherTokenAddress;
        owner = msg.sender;
    }

    ///  mapping 

    mapping(address => uint) UsersTokenForStable;
    mapping(address => uint) UsersEthForStable;
    mapping(address => uint) UsersTokenForEth; 
    mapping(address => bool) Desposited;
    mapping(address => uint) Stable; 
    mapping(address => uint) Eths; 

    /// events 
    event depositedTokenForStable(address indexed  depositor, uint amountofToken);


    /// custom errors
    
    /// zero tokens
    error ZeroTokens();

    /// not the exact amount of tokens
    error NotexactAmount();

    /// @dev user deposits a token for a stable token;
    
 
    function depositeTokenForStable(uint amountTokens) external{  
        /// @param amount of tokens to be the collateral
        if(amountTokens < 0){
            revert ZeroTokens();
        }
        bool sentOthers = IERC20(otherTokenAddress).transferFrom(msg.sender,address(this), amountTokens);
        require(sentOthers , "failed");
        UsersTokenForStable[msg.sender] = amountTokens;
        bool sentStable = IERC20(StableTokenaddress).transfer(msg.sender, amountTokens);
        require(sentStable, "failed");
        Desposited[msg.sender] = true;
        emit depositedTokenForStable(msg.sender, amountTokens);
    }  

    /// @dev user can also deposit for a settle number of stable coin//////////

    function depositeEthForStable() external payable {
        if(msg.value < 0){
            revert ZeroTokens();
        }
        UsersEthForStable[msg.sender] += msg.value;
        uint stable = StableAmount(msg.value);
        Stable[msg.sender] = stable;
        bool sentStable = IERC20(StableTokenaddress).transfer(msg.sender, stable);
        require(sentStable, "failed");
        Desposited[msg.sender] = true;
        emit depositedTokenForStable(msg.sender, msg.value);
    }  

    /// @dev user can deposit token for eth

    function depositeTokenForEth(uint otherToken) external{
         /// @param amount of tokens to be the collater
        if(otherToken < 0){
            revert ZeroTokens();
        }
        UsersTokenForEth[msg.sender] = otherToken;
        uint eth = otherToken * 2;
        Eths[msg.sender] = eth;
        bool sentStable = IERC20(otherTokenAddress).transfer(address(this), otherToken);
        require(sentStable, "failed");
        (bool sent,) = payable(msg.sender).call{value:eth}(""); 
        require(sent, "failed");
        Desposited[msg.sender] = true;
        emit depositedTokenForStable(msg.sender, otherToken);
    }

    /// @dev calculation for the amount of stable coin to be transfer for wei

    function StableAmount(uint amount) internal  pure returns(uint){
        uint _amount = amount / 2;
        return _amount;   
    }

    /// @dev user returning stablecoin and gets he token back when the conditions are meant

    function returnStableForToken(uint returnStables) external {
         /// @param amount of stable to be returned
        require(Desposited[msg.sender] == true, "didn't deposit");
        uint sent = UsersTokenForStable[msg.sender];
        if(returnStables != sent){
            revert NotexactAmount();
        }
        bool sentStable = IERC20(StableTokenaddress).transfer(address(this), returnStables);
        require(sentStable , "failed");
        bool  sentOthers  = IERC20(otherTokenAddress).transfer(msg.sender, returnStables);
        require(sentOthers, "failed");
    }

    /// @dev user returns stablecoin and gets his eth back 

    function returnStableForEth(uint returnstables) external{
         /// @param amount of stable to be returned
        require(Desposited[msg.sender] == true, "didn't deposit");
        uint stable = Stable[msg.sender];
        if(returnstables != stable){
            revert NotexactAmount();
        }
        bool  sentOthers  = IERC20(StableTokenaddress).transfer(address(this), returnstables);
        require(sentOthers, "failed"); 
        uint deposit = UsersEthForStable[msg.sender]; 
        (bool sent,) = payable(msg.sender).call{value:deposit}(""); 
        require(sent, "failed");
    }

    /// @dev users returns eth for his token

    function returnEthForToken() external payable {
        require(Desposited[msg.sender] == true, "didn't deposit");
        uint receivedTokens = UsersTokenForEth[msg.sender];
        uint senteth = Eths[msg.sender];
        if(msg.value != senteth){
            revert NotexactAmount();
        }  
        bool  sentOthers  = IERC20(otherTokenAddress).transfer(msg.sender, receivedTokens);
        require(sentOthers, "failed"); 
    }  
}