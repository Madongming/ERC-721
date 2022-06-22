//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./ERC165.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Receiver.sol";
import "./Strings.sol";
import "./Address.sol";

contract ERC721 is IERC721, ERC165, IERC721Metadata {
    using Strings for uint256;
    using Address for address;
    
  string private _name;
  string private _symbol;

  mapping(address => uint256) private _balances; // 用户映射 token个数，谁有几个token
  mapping(uint256 => address) private _owners; // tokenid 映射用户，token是谁的
  mapping(uint256 => address) private _tokenApprovals; // tokenid映射授权的用户，将这个token给谁了
  mapping(address => mapping(address => bool)) private _operatorApprovals; // 用户映射操作者是否操作，将账户的token授权个另一个用户

  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
  }

  function mint(address _account, uint256 _tokenId) public virtual {
    require(_account != address(0), "ERC721: mint to the zero address");
    require(_owners[_tokenId] == address(0), "ERC721: token already minted");

    _balances[_account] += 1;
    _owners[_tokenId] = _account;

    emit Transfer(address(0), _account, _tokenId);
  }
  
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns(bool) {
    return interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      super.supportsInterface(interfaceId);
  }
  
  function balanceOf(address _owner) public view virtual override returns(uint256 _balance) {
    require(_owner != address(0), "ERC721: invalid owner address");
    return _balances[_owner];
  }

  function ownerOf(uint256 _tokenId) public view virtual override returns(address) {
      address _owner = _owners[_tokenId];
    require(_owner != address(0), "ERC721: invalid token ID");
    return _owner;
  }

  function name() public view virtual override returns(string memory) {
    return _name;
  }

  function symbol() public view virtual override returns(string memory) {
    return _symbol;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns(string memory) {
    require(_owners[_tokenId] != address(0));

    string memory baseURI = _baseURI();
    return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, _tokenId.toString())) : "";
  }

    // 在继承中实现
  function _baseURI() internal view virtual returns(string memory) {
    return "";
  }

  function approve(address _to, uint256 _tokenId) public virtual override {
    require(_owners[_tokenId] != _to, "ERC721: approval to current owner");
    require(_owners[_tokenId] == msg.sender ||
            _operatorApprovals[_owners[_tokenId]][msg.sender], "ERC721: approve caller is not token owner nor approved for all");
    _approve(_to, _tokenId);
  }

  function _approve(address _to, uint256 _tokenId) private {
    _tokenApprovals[_tokenId] = _to;
    emit Approval(_owners[_tokenId], _to, _tokenId);
  }

  function getApproved(uint256 _tokenId) public view virtual override returns(address) {
      require(_owners[_tokenId] != address(0), "ERC721: invalid token ID");
    return _tokenApprovals[_tokenId];
  }

  function setApprovalForAll(address _operator, bool _approved) public virtual override {
    require(_operator != msg.sender, "ERC721: approve to caller");
    _operatorApprovals[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
    require(_from == _owners[_tokenId] ||
            _operatorApprovals[_owners[_tokenId]][_to] ||
            _tokenApprovals[_tokenId] == _to, "ERC721: caller is not token owner nor approved");
    _transfer(_from, _to, _tokenId);
  }

  function _transfer(address _from, address _to, uint256 _tokenId) public virtual {
    require(_from == _owners[_tokenId], "ERC721: transfer from incorrect owner");
    require(_to != address(0), "ERC721: transfer to the zero address");
    _approve(address(0), _tokenId); // 清空授权
    _balances[_from] -= 1;
    _balances[_to] += 1;
    _owners[_tokenId] = _to;

    emit Transfer(_from, _to, _tokenId);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) public virtual override {
    require(_from == _owners[_tokenId] ||
            _operatorApprovals[_owners[_tokenId]][_to] ||
            _tokenApprovals[_tokenId] == _to, "ERC721: caller is not token owner nor approved");
    _safeTransferFrom(_from, _to, _tokenId, data);
  }

  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public virtual {
    _transfer(_from, _to, _tokenId);
    require(_checkOnERC721Received(_from, _to, _tokenId, _data));
  }

  function _checkOnERC721Received(
                                  address from,
                                  address to,
                                  uint256 tokenId,
                                  bytes memory data
                                  ) private returns (bool) {
    if (to.isContract()) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          /// @solidity memory-safe-assembly
          assembly {
            revert(add(32, reason), mload(reason))
              }
        }
      }
    } else {
      return true;
    }
  }

  function isApprovedForAll(address _owner, address _operator) public view virtual override returns(bool) {
    return _operatorApprovals[_owner][_operator];
  }
}
