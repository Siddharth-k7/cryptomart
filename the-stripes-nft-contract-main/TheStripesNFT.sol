// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TheStripesNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Strings for uint256;
    using Address for address;

    // State variables
    string public baseURI;
    string public baseExtension = ".json";
    uint256 public cost = 0.05 ether;
    uint256 public presaleCost = 0.03 ether;
    uint256 public maxSupply = 992;
    uint256 public maxMintAmount = 20;
    bool public paused = false;

    mapping(address => bool) public whitelisted;
    mapping(address => bool) public presaleWallets;

    // Constructor with all proper initializations
    constructor(
        string memory _name,
        string memory _symbol,
        string memory _initBaseURI
    ) ERC721(_name, _symbol) Ownable(msg.sender) ReentrancyGuard() {
        require(20 <= maxSupply, "Initial mint exceeds maxSupply");
        setBaseURI(_initBaseURI);

        // Mint initial tokens to deployer
        for (uint256 i = 1; i <= 20; i++) {
            _safeMint(msg.sender, i);
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function mint(address _to, uint256 _mintAmount) public payable nonReentrant {
        uint256 supply = totalSupply();
        require(!paused, "Contract is paused");
        require(_mintAmount > 0, "Must mint at least 1");
        require(_mintAmount <= maxMintAmount, "Exceeds max mint amount");
        require(supply + _mintAmount <= maxSupply, "Exceeds max supply");

        if (msg.sender != owner()) {
            uint256 requiredAmount;
            if (!whitelisted[msg.sender]) {
                requiredAmount = presaleWallets[msg.sender]
                    ? presaleCost * _mintAmount
                    : cost * _mintAmount;
            }
            require(msg.value >= requiredAmount, "Insufficient payment");

            // ✅ Corrected refund: static call to Address.sendValue
            if (msg.value > requiredAmount) {
                Address.sendValue(payable(msg.sender), msg.value - requiredAmount);
            }
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            _safeMint(_to, supply + i);
        }
    }

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(ownerOf(tokenId) != address(0), "URI query for nonexistent token");

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
            : "";
    }

    // ====== Owner functions ======
    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost;
    }

    function setPresaleCost(uint256 _newCost) public onlyOwner {
        presaleCost = _newCost;
    }

    function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
        maxMintAmount = _newmaxMintAmount;
    }

    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

    function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function whitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = true;
    }

    function removeWhitelistUser(address _user) public onlyOwner {
        whitelisted[_user] = false;
    }

    function addPresaleUser(address _user) public onlyOwner {
        presaleWallets[_user] = true;
    }

    function add100PresaleUsers(address[100] memory _users) public onlyOwner {
        for (uint256 i = 0; i < 100; i++) {
            presaleWallets[_users[i]] = true;
        }
    }

    function removePresaleUser(address _user) public onlyOwner {
        presaleWallets[_user] = false;
    }

    // ✅ Withdraw function for owner
    function withdraw() public onlyOwner nonReentrant {
        Address.sendValue(payable(owner()), address(this).balance);
    }
}
