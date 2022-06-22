import "@nomiclabs/hardhat-ethers";
import { expect } from "chai";
import { ethers as hre } from "hardhat";
import { BigNumber } from "ethers";

let AccountA: any;
let AccountB: any;
let AccountC: any;

const ZeroAddress = "0x0000000000000000000000000000000000000000";

const BigZero = BigNumber.from("0");
const BigOne = BigNumber.from("1");

describe("ERC721", function() {

  async function createERC721() {
    const ERC721 = await hre.getContractFactory("ERC721");
    const erc721 = await ERC721.deploy("Cody", "CD");
    await erc721.deployed();
    [AccountA, AccountB, AccountC] = await hre.getSigners();
    return erc721
  }

  let erc721: any;
  before(async function() {
    erc721 = await createERC721();
  });

  it("Should return the erc721 name is Cody", async function() {
    expect(await erc721.name()).to.equal("Cody");
  });

  it("Should return the erc721 symbol is CD", async function() {
    expect(await erc721.symbol()).to.equal("CD");
  });

  it("Mint One token for AccountA", async function() {
    await erc721.mint(AccountA.address, BigZero);
    expect(await erc721.balanceOf(AccountA.address)).to.equal(BigOne);
    expect(await erc721.ownerOf(BigZero)).to.equal(AccountA.address);
  });

  it("Approval token of an Account to an other", async function() {
    await erc721.approve(AccountB.address, BigZero);
    expect(await erc721.getApproved(BigZero)).to.equal(AccountB.address);
  });

  it("Transfer token from Account to an other", async function() {
    await erc721.connect(AccountB).transferFrom(AccountA.address, AccountC.address, BigZero);
    expect(await erc721.balanceOf(AccountA.address)).to.equal(BigZero);
    expect(await erc721.balanceOf(AccountB.address)).to.equal(BigZero);
    expect(await erc721.balanceOf(AccountC.address)).to.equal(BigOne);
    expect(await erc721.ownerOf(BigZero)).to.equal(AccountC.address);
  });

  it("Set approval for all of account, Check it", async function() {
    await erc721.connect(AccountC).setApprovalForAll(AccountA.address, true);
    expect(await erc721.isApprovedForAll(AccountC.address, AccountA.address)).to.equal(true);
  });
});
