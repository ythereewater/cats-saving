pragma solidity ^0.4.17;

import "truffle/Assert.sol";   // 引入的断言
import "truffle/DeployedAddresses.sol";  // 用来获取被测试合约的地址
import "../contracts/Adoption.sol";      // 被测试合约

contract TestAdoption {
  Adoption adoption = Adoption(DeployedAddresses.Adoption());

  // 领养测试用例
  function testUserCanAdoptCat() public {
    uint returnedId = adoption.adopt(8);

    uint expected = 8;
    Assert.equal(returnedId, expected, "Adoption of cat ID 8 should be recorded.");
  }

  // 流浪猫所有者测试用例
  function testGetAdopterAddressByCatId() public {
    // 期望领养者的地址就是本合约地址，因为交易是由测试合约发起交易，
    address expected = this;
    address adopter = adoption.adopters(8);
    Assert.equal(adopter, expected, "Owner of cat ID 8 should be recorded.");
  }

    // 测试所有领养者
  function testGetAdopterAddressByCatIdInArray() public {
  // 领养者的地址就是本合约地址
    address expected = this;
    address[16] memory adopters = adoption.getAdopters();
    Assert.equal(adopters[8], expected, "Owner of cat ID 8 should be recorded.");
  }
}