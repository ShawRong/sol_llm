// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Timelock {
    address public owner;
    uint256 public amount;
    uint256 public constant MINIMUM_AMOUNT = 1000 wei; // 设置最低取款金额
    mapping(address => string) private keys; // 存储每个存款者的密钥
    mapping(address => uint256) private keyExpiration; // 存储每个存款者的密钥有效期
    uint256 valid_time = 100; // 每个存款者的密钥的持续时间
    uint256 minute = 60; // 定义时间

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed owner, uint256 amount);
    event KeyGenerated(address indexed user, string key);
    
    constructor() {
        owner = msg.sender;
    }

    // 存入金额并设置解锁时间
    function deposit() external payable {
        require(msg.value > 0, "You must send some ether");
        amount += msg.value;

        // 如果没有注册过，就注册一份数据 
        if (bytes(keys[msg.sender]).length == 0) {
            keys[msg.sender] = generateKey(); // 生成密钥
            keyExpiration[msg.sender] = block.timestamp + valid_time * minute; // 新创建有效期
        } else {
            // 延长已存在密钥的有效期
            keys[msg.sender] = generateKey(); // 生成新密钥
            keyExpiration[msg.sender] += valid_time * minute; // 延长有效期
        }

        emit Deposited(msg.sender, msg.value);
        emit KeyGenerated(msg.sender, keys[msg.sender]);
    }

    // 提取金额，如果未达到最低金额则无法提取
    function withdraw() external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount >= MINIMUM_AMOUNT, "Insufficient balance for withdrawal");

        uint256 amountToWithdraw = amount;
        amount = 0; // 重置金额以避免重入攻击
        payable(owner).transfer(amountToWithdraw);
        
        emit Withdrawn(owner, amountToWithdraw);
    }

    // 查询合约中的余额
    function getBalance() external view returns (uint256) {
        return amount;
    }

    // 查询密钥，仅限存款者
    function getKey() external view returns (string memory) {
        require(block.timestamp < keyExpiration[msg.sender], "Key has expired"); // 检查密钥是否过期
        return keys[msg.sender];
    }

    // 检查用户提供的密钥是否与存储的密钥匹配
    function checkKey(address user, string calldata keyToCheck) external view returns (bool) {
        require(block.timestamp < keyExpiration[user], "Key has expired"); // 检查密钥是否过期
        return keccak256(abi.encodePacked(keys[user])) == keccak256(abi.encodePacked(keyToCheck));
    }

    // 生成随机密钥（简单示例）
    function generateKey() private view returns (string memory) {
        return string(abi.encodePacked("KEY-", uint2str(block.timestamp))); // 生成简单的密钥
    }

    // 将 uint 转换为 string
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        j = _i;
        while (j != 0) {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        return string(bstr);
    }

}