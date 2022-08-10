// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface Pair {
    
    function sync() external;

}

interface Factory {

    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);

}

interface Router {
    
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

}

contract TeenDoge is ERC20, Ownable {

    using SafeMath for uint256;

    bool public isFeesEnabled = false;
    address[] public routers;
    mapping(address => bool) public isValidRouter;
    mapping(address => bool) public isValidPair;
    uint256 public burnFee = 125;
    uint256 public liquidityFee = 125;
    uint256 public feeDivider = 100;

    event BurnAndLiquidityFee(address spender, uint256 burnFee, uint256 liquidityFee);
    event NewExchangeAdded(address routerAddress, address pairAddress);

    constructor () ERC20("TeenDoge", "TDOGE") {

        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));

        addARouter(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);

    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns(bool) {

        if(isFeesEnabled && isValidPair[recipient]) {
            uint256 _bFee = 0;
            uint256 _lFee = 0;

            (amount, _bFee, _lFee) = _feeSeparator(amount);

            _actionOnFee(sender, recipient, _bFee, _lFee);
        }

        return super.transferFrom(sender, recipient, amount);
    }

    function setFees(uint256 _bFee, uint256 _lFee, uint256 _fDivider) public onlyOwner {
        burnFee = _bFee;
        liquidityFee = _lFee;
        feeDivider = _fDivider;
    }

    function setFeesEnabled(bool val) public onlyOwner {
        isFeesEnabled = val;
    }

    function addARouter(address _routerAddress) public onlyOwner {
        require(_routerAddress != address(0), "Router Can't Be A Zero Address");
        require(!isValidRouter[_routerAddress], "Is Already Added");

        Router _router = Router(_routerAddress);
        Factory _factory = Factory(_router.factory());
        address _pairAddress = _factory.getPair(address(this), _router.WETH());
        if(_pairAddress == address(0)) {
            _pairAddress = _factory.createPair(address(this), _router.WETH());
        }
        Pair _pair = Pair(_pairAddress);

        routers.push(_routerAddress);

        isValidRouter[address(_router)] = true;
        isValidPair[address(_pair)] = true;

        emit NewExchangeAdded(_routerAddress, address(_pair));
    }

    function getPairs(uint256 _index) public view returns(address) {
        require(_index < routers.length, "Invalid Index");

        Router _router = Router(routers[_index]);
        return Factory(_router.factory()).getPair(address(this), _router.WETH());
    }

    function _feeSeparator(uint256 amount) internal view returns(uint256 _amount, uint256 _bFee, uint256 _lFee) {
        _bFee = amount.mul(burnFee).div(uint256(100).mul(feeDivider));
        _lFee = amount.mul(liquidityFee).div(uint256(100).mul(feeDivider));
        _amount = amount.sub(_bFee).sub(_lFee);
    }

    function _actionOnFee(address _sender, address _recipient, uint256 _bFee, uint256 _lFee) internal {
        _burn(_sender, _bFee.add(_lFee));
        _mint(_recipient, _lFee);
        Pair(_recipient).sync();

        emit BurnAndLiquidityFee(_sender, _bFee, _lFee);
    }

}