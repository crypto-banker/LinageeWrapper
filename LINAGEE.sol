//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface ILinagee {
    function name(address _owner) external view returns (bytes32);

    function owner(bytes32 _name) external view returns (address);

    function content(bytes32 _name) external view returns (bytes32);

    function addr(bytes32 _name) external view returns (address);

    function subRegistrar(bytes32 _name) external view returns(address);

    // REAL?
    function Registrar() external view returns (address);

    function reserve(bytes32 _name) external;
    
    function transfer(bytes32 _name, address _newOwner) external;

    function setSubRegistrar(bytes32 _name, address _registrar) external;

    function setAddress(bytes32 _name, address _a, bool _primary) external;

    function setContent(bytes32 _name, bytes32 _content) external;

    function disown(bytes32 _name) external;

    function register(bytes32 _name) external returns (address);
}

/**
 * Wrap a Linagee NFTs (from address 0x5564886ca2C518d1964E5FCea4f423b41Db9F561) in an ERC721 package.
 * 
 * For minting a new token and immediately wrapping it, simply call `reserve`.
 * 
 * For wrapping an existing token:
 * 1) Prove ownership of the token by calling `proveOwnership`
 * 2) transfer the NFT directly to this contract
 * 3) call the `wrap` function
 */
contract LinageeWrapper is ERC721 {
    // the contract
    ILinagee public constant LINAGEE = ILinagee(0x5564886ca2C518d1964E5FCea4f423b41Db9F561);

    // "name" => owner who can wrap the Linagee NFT
    mapping(bytes32 => address) public canWrapNft;

    modifier onlyOwnerOf(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "onlyOwnerOf tokenId");
        _;
    }

    constructor() ERC721("Linagee Wrapper", "LINAGEE") {}

    // create a new NFT and immediately wrap it.
    function reserve(bytes32 _name) external {
        // check that this contract *does not* own the NFT, as a proxy for it not existing yet
        require(LINAGEE.owner(_name) != address(this), "NFT already exists");
        // reserve the name
        LINAGEE.reserve(_name);
        // wrap the NFT
        _wrap(_name);
    }

    // prove that you currently own a Linagee NFT. next you can transfer it to this contract, then wrap it.
    function proveOwnership(bytes32 linageeNftName) external {
        _proveOwnership(linageeNftName);
    }

    // prove that you currently own Linagees NFT. next you can transfer them to this contract, then wrap them.
    function proveOwnership(bytes32[] memory linageeNftNames) external {
        for (uint i = 0; i < linageeNftNames.length; ++i) {
            _proveOwnership(linageeNftNames[i]);
        }
    }

    // internal function for proving ownership
    function _proveOwnership(bytes32 linageeNftName) internal {
        // verify ownership
        require(LINAGEE.owner(linageeNftName) == msg.sender, "not owner");
        // write to mapping
        canWrapNft[linageeNftName] = msg.sender;
    }

    // wrap a single NFT after proving ownership of it, and *then* transferring it to this contract
    function wrap(bytes32 linageeNftName) external {
         // verify that the person held the NFT and proved ownership before transferring NFT to this contract
        require(canWrapNft[linageeNftName] == msg.sender, "not in mapping");
        _wrap(linageeNftName);
    }

    // wrap a single NFT after proving ownership of it, and *then* transferring it to this contract
    function wrap(bytes32[] memory linageeNftNames) external {
        for (uint i = 0; i < linageeNftNames.length; ++i) {
            // verify that the person held the NFT and proved ownership before transferring NFT to this contract
            require(canWrapNft[linageeNftNames[i]] == msg.sender, "not in mapping");
            _wrap(linageeNftNames[i]);
        }
    }

    // internal wrapping function
    function _wrap(bytes32 linageeNftName) internal {
        // verify that the NFT has been transferred to this contract
        require(LINAGEE.owner(linageeNftName) == address(this), "must transfer NFT first");
        // erase mapping
        canWrapNft[linageeNftName] = address(0);
        // mint NFT
        _mint(msg.sender, uint256(linageeNftName));
    }
    
    // unwrap a token to receive the underlying Linagee NFT
    function unwrap(uint256 tokenId) external {
        _unwrap(tokenId);
    }

    // unwrap tokens to receive the underlying Linagee NFTs
    function unwrap(uint256[] memory tokenIds) external {
        for (uint i = 0; i < tokenIds.length; ++i) {
            _unwrap(tokenIds[i]);
        }
    }

    // internal wrapping function
    function _unwrap(uint256 tokenId) internal onlyOwnerOf(tokenId) {
        _burn(tokenId);
        LINAGEE.transfer(bytes32(tokenId), msg.sender);
    }

    // ERC721 standard compliance. We return whatever content is stored for the tokenId / name
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);
        string memory _content = string(abi.encodePacked(LINAGEE.content(bytes32(tokenId))));
        return _content;
    }

    // WRAPPERS FOR LINAGEE FUNCTIONS ('WRITE' mutability)
    function setSubRegistrar(bytes32 _name, address _registrar) external onlyOwnerOf(uint256(_name)) {
        LINAGEE.setSubRegistrar(_name, _registrar);
    }
    function setAddress(bytes32 _name, address _a, bool _primary) external onlyOwnerOf(uint256(_name)) {
        LINAGEE.setAddress(_name, _a, _primary);
    }
    function setContent(bytes32 _name, bytes32 _content) external onlyOwnerOf(uint256(_name)) {
        LINAGEE.setContent(_name, _content);
    }
    // unclear on what this function is for
    function register(bytes32 _name) external onlyOwnerOf(uint256(_name)) returns (address) {
        return LINAGEE.register(_name);
    }

    // WRAPPERS FOR LINAGEE FUNCTIONS ('READ' MUTABILITY)
    function name(address _owner) external view returns (bytes32) {
        return LINAGEE.name(_owner);
    }

    function owner(bytes32 _name) external view returns (address) {
        address _owner = LINAGEE.owner(_name);
        if (_owner == address(this)) {
            return ownerOf(uint256(_name));
        } else {
            return _owner;
        }
    }

    function content(bytes32 _name) external view returns (bytes32) {
        return LINAGEE.content(_name);
    }

    function addr(bytes32 _name) external view returns (address) {
        return LINAGEE.addr(_name);
    }

    function subRegistrar(bytes32 _name) external view returns(address) {
        return LINAGEE.subRegistrar(_name);
    }
}