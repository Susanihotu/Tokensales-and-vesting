/**
 *Submitted for verification at polygonscan.com on 2022-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

interface IERC20 {
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract XaneTokenSales {

    struct UserClaim {
        uint256 amountLocked;
        uint256 totalAmountToRecieve;
        uint256 amountClaimed;
        uint256 time;
        uint256 nextClaim;
    }

    mapping(address => UserClaim) public userClaim;

    bool public checkSaleStatus;
    address public xaneToken;
    address multiSigContractAddress;
    address public USDT;
    address public USDC;

    address public owner;
    uint256 public totalAmountSoldOut;
    uint256 public Price;
    uint256 public maticFee;
    uint256 public fee;
    uint256 public minimumPurchaseAmount;

    event sales(address token, address indexed to, uint256 amountIn, uint256 amountRecieved);
    event rewardClaim(address indexed token, address indexed claimer, uint256 reward, uint256 time);

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    // Only allow the owner to do specific tasks
    modifier onlyOwner() {
        require(_msgSender() == owner,"TIKI TOKEN: YOU ARE NOT THE OWNER.");
        _;
    }

    constructor( 
        address _xanetoken, 
        address _usdt, 
        address _usdc, 
        uint256 _price, 
        uint256 _fee, 
        uint256 mFee, 
        address multiSig, 
        uint256 _minimumAmount
        ) {
        owner =  _msgSender();
        checkSaleStatus = true;
        xaneToken = _xanetoken;
        USDT = _usdt;
        USDC = _usdc;
        Price = _price;
        fee = _fee;
        maticFee = mFee;
        multiSigContractAddress = multiSig;
        minimumPurchaseAmount = _minimumAmount;
    }

    function updateMinimumAMount(uint256 _newMinimumAmount) external onlyOwner {
        minimumPurchaseAmount = _newMinimumAmount;
    }

    function buy(uint256 _tokenAmount, address purchaseWith) public {
        require(_tokenAmount ** IERC20(purchaseWith).decimals() > 0, "XANE NETWORK: BUY ATLEAST 1 TOKEN.");
        require(purchaseWith == USDT || purchaseWith == USDC, "Invalid Token Contract");
        uint256 fees = _tokenAmount * 10 ** IERC20(purchaseWith).decimals() - (fee);
        uint256 reward = calculateReward(fees);
        require(checkSaleStatus == true, "XANE NETWORK: SALE HAS ENDED.");
        require(reward >= minimumPurchaseAmount, "Minimum amount require for purchase");
        uint256 addressBalance = IERC20(xaneToken).balanceOf(address(this));
        require(addressBalance >= reward, "XANE NETWORK: Contract Balance too low for amount provided");
        require(IERC20(purchaseWith).transferFrom(_msgSender(), address(multiSigContractAddress), _tokenAmount * 10 ** IERC20(purchaseWith).decimals() ), "XANE NETWORK: TRANSFERFROM FAILED!");
        
        UserClaim storage claim = userClaim[msg.sender];
        claim.amountLocked += fees;
        claim.totalAmountToRecieve += reward;
        claim.time = block.timestamp;
        claim.nextClaim = block.timestamp + 5200086; // 60 days 4 hours
        uint256 getTenPercent = (reward * 10 ** IERC20(xaneToken).decimals()) / 100 ** IERC20(xaneToken).decimals();
        totalAmountSoldOut += getTenPercent;
        claim.amountClaimed += getTenPercent;
        IERC20(xaneToken).transfer(_msgSender(), getTenPercent);

        emit sales(purchaseWith, _msgSender(), _tokenAmount, reward);
    }

    function buyWithMatic() external payable{
        uint256 p = Price;
        uint256 value = msg.value;
        uint256 reward = value/ p;
        require(reward >= minimumPurchaseAmount, "Minimum amount require for purchase");
        uint256 addressBalance = IERC20(xaneToken).balanceOf(address(this));
        require(addressBalance >= reward, "XANE NETWORK: Contract Balance too low for amount provided");
        require(checkSaleStatus == true, "XANE NETWORK: SALE HAS ENDED.");
        payable(multiSigContractAddress).transfer(value);
        uint256 debitFee = value - maticFee;
        UserClaim storage claim = userClaim[msg.sender];
        claim.amountLocked += (debitFee);
        claim.totalAmountToRecieve += reward;
        claim.time = block.timestamp;
        claim.nextClaim = block.timestamp + 5200086; // 60 days 4 hours
        uint256 getTenPercent = (debitFee * 10 ** IERC20(xaneToken).decimals()) / 100 ** IERC20(xaneToken).decimals();
        totalAmountSoldOut += getTenPercent;
        claim.amountClaimed += getTenPercent;
        IERC20(xaneToken).transfer(_msgSender(), getTenPercent);
        emit sales(address(zaieToken), _msgSender(), msg.value, reward);
    }

    function claimReward() external {
        UserClaim storage claim = userClaim[msg.sender];
        uint256 _claim = claim.nextClaim;
        uint256 amountClaimed = claim.totalAmountToRecieve;
        require(block.timestamp > _claim, "XANE: Kindly exercise patience for claim time");
        require(amountClaimed != claim.amountClaimed, "Chruch: No more reward");
        claim.time = block.timestamp;
        claim.nextClaim = block.timestamp + 5200086; // 60 days 4 hours
        uint256 fiftenPercent = (claim.amountLocked * 15 ** IERC20(xaneToken).decimals()) / 100 ** IERC20(xaneToken).decimals();
        claim.amountClaimed += fiftenPercent;
        IERC20(xaneToken).transfer(_msgSender(), fiftenPercent);
        emit rewardClaim(address(xaneToken), _msgSender(), fiftenPercent, block.timestamp);
    }

    function updateMultiSigWl(address newSig) external onlyOwner {
        multiSigContractAddress = newSig;
    }

    function setFee(uint256 _newFeeToken, uint256 mFee) external onlyOwner {
        fee = _newFeeToken;
        maticFee = mFee;
    }

    function calculateReward(uint256 amount) public view returns(uint256) {
        uint256 p = Price;
        uint256 reward = (
            (amount * 10 ** IERC20(xaneToken).decimals()) * 
            1 ** IERC20(xaneToken).decimals()/
            p) * 10 ** IERC20(xaneToken).decimals()
        ;
        return reward ;
    }

    function resetPrice(uint256 newPrice) external onlyOwner {
        Price = newPrice;
    }
    
    // To enable the sale, send RGP tokens to this contract
    function enableSale(bool status) external onlyOwner{

        // Enable the sale
        checkSaleStatus = status;
    }

    // Withdraw (accidentally) to the contract sent eth
    function withdrawBNB() external payable onlyOwner {
        payable(owner).transfer(payable(address(this)).balance);
    }

    // Withdraw (accidentally) to the contract sent ERC20 tokens
    function withdrawToken(address _token) external onlyOwner {
        uint _tokenBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, _tokenBalance);
    }
}