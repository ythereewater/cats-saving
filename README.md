# 智能合约部署报告

编写一个完整的去中心化应用

## 项目背景
    为了解决流浪猫的问题，救助站决定建立一个去中心化应用，让大家来领养流浪猫,我们可以使用在truffle box中，已经提供的pet-shop网站部分的代码，只需要编写合约及交互部分。
    
## 环境搭建

安装Node
安装 Truffle ：npm install -g truffle
安装Ganache

## 创建项目

### 1.建立项目目录并进入

    > mkdir cat_save_project
    > cd cat_save_project
### 2. 使用truffle unbox 创建项目

    > truffle unbox pet-shop
    Downloading...
    Unpacking...
    Setting up...
    Unbox successful. Sweet!

    Commands:

    Compile:        truffle compile
    Migrate:        truffle migrate
    Test contracts: truffle test
    Run dev server: npm run dev
    
    项目目录结构


contracts/ 智能合约的文件夹，所有的智能合约文件都放置在这里，里面包含一个重要的合约Migrations.sol
migrations/ 用来处理部署（迁移）智能合约 ，迁移是一个额外特别的合约用来保存合约的变化。
test/ 智能合约测试用例文件夹
truffle.js/ 配置文件

编写智能合约

智能合约承担着分布式应用的后台逻辑和存储。智能合约使用solidity编写。

在contracts目录下，添加合约文件Adoption.sol

    pragma solidity ^0.4.17;

    contract Adoption {

    address[16] public adopters;  // 保存领养者的地址

    // 领养流浪猫
    function adopt(uint  catId) public returns (uint) {
    require(catId >= 0 && catId <= 15);  // 确保id在数组长度内

    adopters[catId] = msg.sender;        // 保存调用这地址 
    return catId;
    }

    // 返回领养者
    function getAdopters() public view returns (address[16]) {
    return adopters;
    }
    }
    
## 编译部署智能合约

编译
进入项目目录,输入

    > truffle compile
![编译][1]
部署

编译之后，就可以部署到区块链上。
在migrations文件夹下已经有一个1_initial_migration.js部署脚本，用来部署Migrations.sol合约。
Migrations.sol 用来确保不会部署相同的合约。
现在创建一个自己的部署脚本2_deploy_contracts.js

    var Adoption = artifacts.require("Adoption");

    module.exports = function(deployer) {
     deployer.deploy(Adoption);
    };
    
在执行部署之前，需要确保有一个区块链运行, 可以使用
Ganache来开启一个私链来进行开发测试，默认会在7545端口上运行一个开发链。
Ganache 启动之后是这样：
![Ganache][2]

接下来执行部署命令:

    truffle  migrate
![部署][3]

在打开的Ganache里可以看到区块链状态的变化，现在产生了4个区块。

![Ganache2][4]


这时说明已经智能合约已经部署好了。

## 测试
现在我们来测试一下智能合约。

在test目录下新建一个TestAdoption.sol

            pragma solidity ^0.4.17;
        
            import "truffle/Assert.sol";   // 引入的断言
            import "truffle/DeployedAddresses.sol";  // 用来获取被测试合约的地址
        import "../contracts/Adoption.sol";      // 被测试合约
        
        contract TestAdoption {
          Adoption adoption = Adoption(DeployedAddresses.Adoption());
        
          // 领养测试用例
          function testUserCanAdoptPet() public {
            uint returnedId = adoption.adopt(8);
        
            uint expected = 8;
            Assert.equal(returnedId, expected, "Adoption of pet ID 8 should be recorded.");
          }
        
          // 宠物所有者测试用例
          function testGetAdopterAddressByPetId() public {
            // 期望领养者的地址就是本合约地址，因为交易是由测试合约发起交易，
            address expected = this;
            address adopter = adoption.adopters(8);
            Assert.equal(adopter, expected, "Owner of pet ID 8 should be recorded.");
          }
        
            // 测试所有领养者
          function testGetAdopterAddressByPetIdInArray() public {
          // 领养者的地址就是本合约地址
            address expected = this;
            address[16] memory adopters = adoption.getAdopters();
            Assert.equal(adopters[8], expected, "Owner of pet ID 8 should be recorded.");
          }
        }
        
### 运行测试用例
在终端中，执行

    truffle test
    
![此处输入图片的描述][5]

说明测试成功

### 创建用户接口和智能合约交互

编写，部署和测试合约完成后，开始编写UI。

在Truffle Box `pet-shop`框架中，已经在src/文件夹中初始化好了前端代码。

打开`src/js/app.js`进行编辑

#### 初始化web3

编辑app.js

修改initWeb3():

    initWeb3: function() {
    // Is there an injected web3 instance?
    if (typeof web3 !== 'undefined') {
      App.web3Provider = web3.currentProvider;
    } else {
      // If no injected web3 instance is detected, fall back to Ganache
      App.web3Provider = new Web3.providers.HttpProvider('http://localhost:7545');
    }
    web3 = new Web3(App.web3Provider);

    return App.initContract();
  }
  
 #### 实例化合约
 
 使用truffle-contract会保存合约部署的信息，就不需要手动修改合约地址，所以修改initContract()代码：
 
    initContract: function() {
      // 加载Adoption.json，保存了Adoption的ABI（接口说明）信息及部署后的网络(地址)信息，它在编译合约的时候生成ABI，在部署的时候追加网络信息
      $.getJSON('Adoption.json', function(data) {
        // 用Adoption.json数据创建一个可交互的TruffleContract合约实例。
        var AdoptionArtifact = data;
        App.contracts.Adoption = TruffleContract(AdoptionArtifact);

    // Set the provider for our contract
    App.contracts.Adoption.setProvider(App.web3Provider);

    // Use our contract to retrieve and mark the adopted pets
    return App.markAdopted();
  });
  return App.bindEvents();
}

#### 处理领养事件
修改markAdopted()代码：

    markAdopted: function(adopters, account) {
    var adoptionInstance;

    App.contracts.Adoption.deployed().then(function(instance) {
      adoptionInstance = instance;

      // 调用合约的getAdopters(), 用call读取信息不用消耗gas
      return adoptionInstance.getAdopters.call();
    }).then(function(adopters) {
      for (i = 0; i < adopters.length; i++) {
        if (adopters[i] !== '0x0000000000000000000000000000000000000000') {
          $('.panel-pet').eq(i).find('button').text('Success').attr('disabled', true);
        }
      }
    }).catch(function(err) {
      console.log(err.message);
    });
    }
修改handleAdopt()代码：

      handleAdopt: function(event) {
    event.preventDefault();

    var petId = parseInt($(event.target).data('id'));

    var adoptionInstance;

    // 获取用户账号
    web3.eth.getAccounts(function(error, accounts) {
      if (error) {
        console.log(error);
      }

      var account = accounts[0];

      App.contracts.Adoption.deployed().then(function(instance) {
        adoptionInstance = instance;

        // 发送交易领养宠物
        return adoptionInstance.adopt(petId, {from: account});
      }).then(function(result) {
        return App.markAdopted();
      }).catch(function(err) {
        console.log(err.message);
      });
    });
    }

### 在浏览器中运行

选择安装MetaMask，MetaMask是一款插件形式的以太坊轻客户端，开发过程中使用MetaMask和我们的dapp进行交互是个很好的选择，安装完成后，浏览器工具条会显示一个小狐狸图标。

配置钱包
进入MetaMask，会显示如下信息：
![此处输入图片的描述][6]

我们点击`Import with seed phrase`，输入Ganache显示的助记词。

    candy maple cake sugar pudding cream honey rich smooth crumble sweet treat
然后设置我们的密码
![此处输入图片的描述][7]

点击`IMPORT`

#### 连接开发区块链网络
默认连接以太坊主网，我们选择Custom RPC，添加一个网络：http://127.0.0.1:7545
![此处输入图片的描述][8]
配置完成

### 安装和配置lite-server

接下来需要本地的web 服务器提供服务的访问， `Truffle Box pet-shop`里提供了一个lite-server可以直接使用，我们看看它是如何工作的。
bs-config.json指示了lite-server的工作目录。

    {
      "server": {
        "baseDir": ["./src", "./build/contracts"]
      }
    }

./src 是网站文件目录
./build/contracts 是合约输出目录

以此同时，在package.json文件的scripts中添加了dev命令：

    "scripts": {
      "dev": "lite-server",
      "test": "echo \"Error: no test specified\" && exit 1"
    },

当运行npm run dev的时候，就会启动lite-server

### 启动服务

    npm run dev
    
打开http://localhost:3000/即可进入
![此处输入图片的描述][9]

点击adopter,即可领养流浪猫
![此处输入图片的描述][10]

点击confirm，交易成功
![此处输入图片的描述][11]

交易详情
![此处输入图片的描述][12]0


#### 参考

这个项目学习参考了博文[一步步教你开发、部署第一个去中心化应用(Dapp) - 宠物商店][https://learnblockchain.cn/2018/01/12/first-dapp/]


  [1]: https://i.loli.net/2018/11/26/5bfbda108d72f.png
  [2]: https://i.loli.net/2018/11/26/5bfbd94403169.png
  [3]: https://i.loli.net/2018/11/26/5bfbda6dae7dc.png
  [4]: https://i.loli.net/2018/11/26/5bfbdaa176276.png
  [5]: https://i.loli.net/2018/11/26/5bfbdb6ace223.png
  [6]: https://i.loli.net/2018/12/23/5c1f92303d128.png
  [7]: https://i.loli.net/2018/12/23/5c1f92c6e4777.png
  [8]: https://i.loli.net/2018/12/23/5c1f9d8d832ce.png
  [9]: https://i.loli.net/2018/12/23/5c1fa7b82f58c.png
  [10]: https://i.loli.net/2018/12/23/5c1fa80df1a37.png
  [11]: https://i.loli.net/2018/12/23/5c1fa8637b7e0.png
  [12]: https://i.loli.net/2018/12/23/5c1fa8bd7c133.png
