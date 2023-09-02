// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Votes.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract VireoX is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, Ownable, ERC721Burnable, EIP712, ERC721Votes {

    struct UserStakeInfo {
        address owner;
        uint256 stakeAmount;
        uint256 lastUpdatedTimestamp;
        uint256 xlevel;
        uint256 xexp;
        uint256 xNumber;
    }

    struct EvolutionInfo {
        uint256 standardExp;
        uint256 level;
        string levelName;
        string uri;
    }

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    mapping(address => UserStakeInfo) public userStakeInfo;
    

    EvolutionInfo[] public evolutionInfos;

    // evolution added exp = K * (amount ** ALPHA) * (timestamp ** BETA)
    uint256 public ALPHA = 1;
    uint256 public BETA = 2;
    uint256 public K = 10;
    
    constructor() ERC721("VireoX", "VireoX") EIP712("VireoX", "1") {
        evolutionInfos.push(EvolutionInfo(100,1,"VireoA","https://static.wikia.nocookie.net/pokemon/images/5/57/%EC%9D%B4%EC%83%81%ED%95%B4%EC%94%A8_%EA%B3%B5%EC%8B%9D_%EC%9D%BC%EB%9F%AC%EC%8A%A4%ED%8A%B8.png/revision/latest/scale-to-width-down/1200?cb=20170404232618&path-prefix=ko"));
        evolutionInfos.push(EvolutionInfo(1000,2,"VireoB","https://static.wikia.nocookie.net/pokemon/images/4/46/%EC%9D%B4%EC%83%81%ED%95%B4%ED%92%80_%EA%B3%B5%EC%8B%9D_%EC%9D%BC%EB%9F%AC%EC%8A%A4%ED%8A%B8.png/revision/latest?cb=20170404232716&path-prefix=ko"));
        evolutionInfos.push(EvolutionInfo(10000,3,"VireoC","https://static.wikia.nocookie.net/pokemon/images/3/34/%EC%9D%B4%EC%83%81%ED%95%B4%EA%BD%83_%EA%B3%B5%EC%8B%9D_%EC%9D%BC%EB%9F%AC%EC%8A%A4%ED%8A%B8.png/revision/latest/scale-to-width-down/250?cb=20170404232813&path-prefix=ko"));
    }

    event GeneratedToken(address user, uint256 tokenId);
    event ConstantsChanged(uint256 ALPHA, uint256 BETA, uint256 K);
    event EditedEvolutionInfo(uint256 level, uint256 standardExp, string levelName, string uri);
    event AddedEvolutionInfo(uint256 level, uint256 standardExp, string levelName, string uri);


    function _baseURI() internal pure override returns (string memory) {
        return "http";
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function safeMint(address to, string memory uri, uint256 stakeAmount) public onlyOwner {
        // User can't mint more than 1 token.
        require(balanceOf(to) == 0, "VireoX: already minted");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        _generateUserInfo(to, stakeAmount, tokenId);
    }

    function _generateUserInfo(address user, uint256 stakeAmount, uint256 tokenId) internal {
        userStakeInfo[user] = UserStakeInfo(user, stakeAmount, block.timestamp, 1, 0, tokenId);
        emit GeneratedToken(user, tokenId);
    }


    function requestEditUserInfo(address user, uint256 stakeAmount) public onlyOwner {
        require(userStakeInfo[user].owner != address(0), "VireoX: user has not staked");
        updateUserEvolution(user);
        userStakeInfo[user].stakeAmount = stakeAmount;
    }


    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        // VireoX is not allowed to transfer, It's SBT.
        require(from == address(0), "VireoX: not allowed to transfer");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    // The following functions are overrides required by Solidity.
    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Votes)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function calculateExp(uint256 amount, uint256 timestamp) public view returns (uint256) {
        return K * (amount ** ALPHA) * (timestamp ** BETA);
    }

    function setConstants(uint256 _ALPHA, uint256 _BETA, uint256 _K) public onlyOwner {
        ALPHA = _ALPHA;
        BETA = _BETA;
        K = _K;
        emit ConstantsChanged(_ALPHA, _BETA, _K);
    }

    function editEvolutionInfo(uint256 level, uint256 standardExp, string memory levelName, string memory uri) public onlyOwner {
        require(level > 0, "VireoX: level must be greater than 0");
        require(standardExp > 0, "VireoX: standardExp must be greater than 0");
        require(bytes(levelName).length > 0, "VireoX: levelName must be greater than 0");
        require(bytes(uri).length > 0, "VireoX: uri must be greater than 0");

        uint256 index = level - 1;
        evolutionInfos[index].standardExp = standardExp;
        evolutionInfos[index].levelName = levelName;
        evolutionInfos[index].uri = uri;
        emit EditedEvolutionInfo(level, standardExp, levelName, uri);
    }

    function addEvolutionInfo(uint256 standardExp, string memory levelName, string memory uri) public onlyOwner {
        require(standardExp > 0, "VireoX: standardExp must be greater than 0");
        require(bytes(levelName).length > 0, "VireoX: levelName must be greater than 0");
        require(bytes(uri).length > 0, "VireoX: uri must be greater than 0");

        evolutionInfos.push(EvolutionInfo(standardExp, evolutionInfos.length + 1, levelName, uri));
        emit AddedEvolutionInfo(evolutionInfos.length, standardExp, levelName, uri);
    }

    /**
        * @return evolution check, new exp, new level
     */
    function updateUserEvolution(address user) public returns (bool, uint256, uint256) {
        // check user has staked
        require(userStakeInfo[user].owner != address(0), "VireoX: user has not staked");
        UserStakeInfo memory userStake = userStakeInfo[user];
        uint256 exp = calculateExp(userStake.stakeAmount, block.timestamp - userStake.lastUpdatedTimestamp);
        uint256 newExp = userStake.xexp + exp;
        userStakeInfo[user].xexp = newExp;
        // check evolution, if evolution is changed, update tokenURI, It can be multiple evolution.
        uint256 currentLevel = userStake.xlevel;
        uint256 nextLevel = currentLevel;
        for (uint256 i = currentLevel; i < evolutionInfos.length; i++) {
            if (newExp >= evolutionInfos[i].standardExp) {
                nextLevel = i + 1;
            }
        }
        if (nextLevel > currentLevel) {
            userStakeInfo[user].xlevel = nextLevel;
            _setTokenURI(userStake.xNumber, evolutionInfos[nextLevel - 1].uri);
        }

        userStakeInfo[user].lastUpdatedTimestamp = block.timestamp;

        return (nextLevel > currentLevel, newExp, nextLevel);
    }

    


}
