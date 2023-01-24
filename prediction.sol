pragma solidity ^0.8.0;

contract PredictionMarket {
    struct Market {
        address creator;
        string title;
        string description;
        bool resolved;
        bool outcome;
        uint256 endTime;
    }
    mapping(uint256 => Market) public markets;
    mapping(uint256 => mapping(address => uint256)) public shares;
    mapping(uint256 => mapping(address => bool)) public resolutions;
    uint256 public nextMarketId;
    event NewMarket(uint256 marketId, address creator, string title, string description, uint256 endTime);
    event MarketResolved(uint256 marketId, bool outcome);
    event SharePurchased(uint256 marketId, address purchaser, uint256 shares);
    event ResolutionSubmitted(uint256 marketId, address submitter, bool resolution);

    constructor() public {
        nextMarketId = 0;
    }

    function createMarket(string memory _title, string memory _description, uint256 _endTime, bool _outcome) public {
        require(msg.sender != address(0), "Only an address can create a market.");
        require(_endTime > now, "End time must be in the future.");
        markets[nextMarketId] = Market(msg.sender, _title, _description, false, _outcome, _endTime);
        emit NewMarket(nextMarketId, msg.sender, _title, _description, _endTime);
        nextMarketId++;
    }

    function buyShares(uint256 _marketId, uint256 _shares) public payable {
        require(msg.value >= _shares, "Not enough ether.");
        require(markets[_marketId].endTime > now, "Market has already ended.");
        require(!markets[_marketId].resolved, "Market has already been resolved.");
        address _marketCreator = markets[_marketId].creator;
        _marketCreator.transfer(msg.value);
        shares[_marketId][msg.sender] += _shares;
        emit SharePurchased(_marketId, msg.sender, _shares);
    }

    function submitResolution(uint256 _marketId, bool _resolution) public {
        require(markets[_marketId].endTime <= now, "Market has not yet ended.");
        require(!markets[_marketId].resolved, "Market has already been resolved.");
        resolutions[_marketId][msg.sender] = _resolution;
    }

    function resolveMarket(uint256 _marketId) public {
        require(markets[_marketId].creator == msg.sender, "Only the market creator can resolve the market.");
        require(markets[_marketId].endTime <= now, "Market has not yet ended.");
        require(!markets[_marketId].resolved, "Market has already been resolved.");
        bool outcome = true;
            for (address key in resolutions[_marketId]) {
            if (resolutions[_marketId][key] != markets[_marketId].outcome) {
                outcome = false;
                break;
            }
        }
        markets[_marketId].resolved = true;
        markets[_marketId].outcome = outcome;
        emit MarketResolved(_marketId, outcome);
        for (address key in shares[_marketId]) {
            if (outcome) {
                key.transfer(shares[_marketId][key] * msg.value);
            }
        }
    }

    function getMarket(uint256 _marketId) public view returns (address, string memory, string memory, bool, bool, uint256) {
        return (markets[_marketId].creator, markets[_marketId].title, markets[_marketId].description, markets[_marketId].resolved, markets[_marketId].outcome, markets[_marketId].endTime);
    }

    function getShares(uint256 _marketId, address _address) public view returns (uint256) {
        return shares[_marketId][_address];
    }

    function getResolution(uint256 _marketId, address _address) public view returns (bool) {
        return resolutions[_marketId][_address];
    }
}
