// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './interface/INFTPoolFactory.sol';
import './NFTPool.sol';

//uniswap工厂
contract NFTPoolFactory is INFTPoolFactory {
    address public feeTo; //收税地址
    address public feeToSetter; //收税权限控制地址
    address public router; //路由地址
    //Pool映射,地址=>地址
    mapping(address => address) public getPool;
    //所有配对数组
    address[] public allPools;
    address public nftVault;
    //配对合约的Bytecode的hash
    bytes32 public constant INIT_CODE_PAIR_HASH = keccak256(abi.encodePacked(type(NFTPool).creationCode));
    //事件:配对被创建
    event PoolCreated(address indexed token0, address pair, uint);

    /**
     * @dev 构造函数
     * @param _feeToSetter 收税开关权限控制
     */
    constructor(address _feeToSetter, address _router, address _nftVault) {
        feeToSetter = _feeToSetter;
        router = _router;
        nftVault = _nftVault;
    }

    /**
     * @dev 查询配对数组长度方法
     */
    function allPoolsLength() external view returns (uint) {
        return allPools.length;
    }

    function getPoolByToken(address token) external view returns (address) {
        return getPool[token];
    }

    /**
     *
     * @param token Token
     * @return pool Pool地址
     * @dev 创建配对
     */
    function createPool(address token, address nftAuction) external returns (address pool) {
        //给bytecode变量赋值"NFTPool"合约的创建字节码
        bytes memory bytecode = type(NFTPool).creationCode;
        //将token0和token1打包后创建哈希
        bytes32 salt = keccak256(abi.encodePacked(token));
        //内联汇编
        //solium-disable-next-line
        assembly {
            //通过create2方法布署合约,并且加盐,返回地址到pair变量
            pool := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        //调用pair地址的合约中的"initialize"方法,传入变量token0,token1
        NFTPool(payable(pool)).initialize(token, router, nftAuction, nftVault);
        //配对映射中设置token = pair
        getPool[token] = pool;
        //配对数组中推入pool地址
        allPools.push(pool);
        //触发配对成功事件
        emit PoolCreated(token, pool, allPools.length);
    }

    /**
     * @dev 设置收税地址
     * @param _feeTo 收税地址
     */
    function setFeeTo(address _feeTo) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeTo = _feeTo;
    }

    /**
     * @dev 收税权限控制
     * @param _feeToSetter 收税权限控制
     */
    function setFeeToSetter(address _feeToSetter) external {
        require(msg.sender == feeToSetter, 'UniswapV2: FORBIDDEN');
        feeToSetter = _feeToSetter;
    }
}
