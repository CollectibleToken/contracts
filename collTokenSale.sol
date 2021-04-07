contract CollTokenSale {
    
    CollToken public token;
    
    address public owner;
    address public beneficiary;
    
    uint public stage;
    uint public preSaleQty;
    uint public publicSaleQty;
    uint public preSalePrice;
    uint public publicSalePrice;
    
    uint public tokenPrice;
    
    uint public tokenSoldTotal;
    uint public tokenSoldStage;
    uint public stageRemain;
    
    uint public totalRaised;
    
    bool public saleOn;
    
    uint public refPercent;
    
    mapping(address => uint) public refEarnings;
    
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event BeneficiarySet(address indexed oldBeneficiary, address indexed newBeneficiary);
    event TokenSale();
    
    modifier isOwner() {
        require(msg.sender == owner, "Only owner can do this!");
        _;
    }
    
    
    constructor(address _tokenAddress) {
        owner = msg.sender;
        beneficiary = msg.sender;
        token = CollToken(_tokenAddress);
        stage = 1;
        preSaleQty = 120000;
        publicSaleQty = 360000;
        preSalePrice = 10000000000000000;
        publicSalePrice = 15000000000000000;
        saleOn = true;
        tokenPrice = 10000000000000000;
        tokenSoldTotal = 0;
        tokenSoldStage = 0;
        stageRemain = 120000;
        totalRaised = 0;
        refPercent = 0;
    }
    
    receive() external payable {
        buyToken(address(0));
    }
    
    function tokenPriceGet() private {
        if (stage == 1) {
            tokenPrice = preSalePrice;
        } else if (stage == 2) {
            tokenPrice = publicSalePrice;
        }
    }
    
    function buyToken(address _ref) public payable {
        
        require(saleOn, 'Token sale is not active!');
        tokenPriceGet();
        require(msg.value >= tokenPrice, 'Not enough payment!');
        
        uint qty = uint(msg.value) / tokenPrice;
        uint change = msg.value % tokenPrice;
        
        if (qty >= stageRemain) {
            change = msg.value - (tokenPrice * stageRemain);
            qty = stageRemain;
            stage++;
            if (stage == 2) {
                stageRemain = publicSaleQty;
                tokenSoldStage = 0;
            } else if (stage > 2) {
                stageRemain = 0;
                saleOn = false;
            }
        }
        
        
        if (change > 0) {
            trans(payable(msg.sender), change);
        }
        
        token.transferFrom(owner, msg.sender, qty);
        
        tokenSoldTotal = tokenSoldTotal + qty;
        tokenSoldStage = tokenSoldStage + qty;
        calcRemain();
        totalRaised = totalRaised + qty * tokenPrice;
        
        if (_ref != address(0) && _ref != address(msg.sender) && refPercent > 0) {
            uint comm = qty * tokenPrice * refPercent / 1000;
            trans(payable(_ref), comm);
            refEarnings[_ref] = refEarnings[_ref] + comm;
        }
        
        emit TokenSale();
        tokenPriceGet();
    }
    
    function calcRemain() internal {
        if (stage == 1) {
            stageRemain = preSaleQty - tokenSoldStage;
        } else if (stage == 2) {
            stageRemain = publicSaleQty - tokenSoldStage;
        }
    }
    
    function setOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
    
    function setBeneficiary(address newBeneficiary) public isOwner {
        emit BeneficiarySet(beneficiary, newBeneficiary);
        beneficiary = newBeneficiary;
    }
    
    function withdrawAll() public isOwner {
        uint amount = address(this).balance;
        payable(beneficiary).transfer(amount);
    }
    
    function withdraw(uint _amount) public isOwner {
        require(_amount <= address(this).balance, 'More than balance!');
        payable(beneficiary).transfer(_amount);
    }
    
    function setPreSaleQty(uint _newPresaleQty) public isOwner {
        if (stage == 1) {
            require(_newPresaleQty >= tokenSoldStage, 'It cannot be less than already sold!');
        }
        preSaleQty = _newPresaleQty;
        calcRemain();
    }
    
    function setPublicSaleQty(uint _newPublicSaleQty) public isOwner {
        if (stage == 2) {
            require(_newPublicSaleQty >= tokenSoldStage, 'It cannot be less than already sold!');
        }
        publicSaleQty = _newPublicSaleQty;
        calcRemain();
    }
    
    function setPreSalePrice(uint _newPresalePrice) public isOwner {
        preSalePrice = _newPresalePrice;
    }
    
    function setPublicSalePrice(uint _newPublicSalePrice) public isOwner {
        publicSalePrice = _newPublicSalePrice;
    }
    
    function setRefPercent(uint _refPercent) public isOwner {
        refPercent = _refPercent;
    }
    
    function saleOnOff(bool _onoff) public isOwner {
        saleOn = _onoff;
    }
    
    function trans(address payable _to, uint _amount) private {
        (bool success,) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
    
}
