// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// Standart ERC20 interfeysi
interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract USDTZSwap {
    address public owner;
    IERC20 public usdt;
    IERC20 public usdtz;

    // 1 USDT = 100 USDT.z, 6 ondalıq üçün 100 * 1e6 = 100000000
    uint256 public rate = 100 * 1e6;
    // Minimum swap 100 USDT (100 * 1e6)
    uint256 public minSwapAmount = 100 * 1e6;

    event Swapped(
        address indexed user,
        address fromToken,
        address toToken,
        uint256 amountIn,
        uint256 amountOut
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _usdt, address _usdtz) {
        owner = msg.sender;
        usdt = IERC20(_usdt);
        usdtz = IERC20(_usdtz);
    }

    // Sürətli dəyişmək üçün
    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function setMinSwapAmount(uint256 _amount) external onlyOwner {
        minSwapAmount = _amount;
    }

    // USDT → USDT.z (1 USDT = 100 USDT.z)
    function swapUsdtToUsdtz(uint256 amount) external {
        require(amount >= minSwapAmount, "Below minimum swap limit");
        require(usdt.transferFrom(msg.sender, address(this), amount), "USDT transfer failed");
        uint256 outAmount = amount * rate / 1e6;
        require(usdtz.balanceOf(address(this)) >= outAmount, "Insufficient USDT.z liquidity");
        require(usdtz.transfer(msg.sender, outAmount), "USDT.z transfer failed");
        emit Swapped(msg.sender, address(usdt), address(usdtz), amount, outAmount);
    }

    // USDT.z → USDT (100 USDT.z = 1 USDT)
    function swapUsdtzToUsdt(uint256 amount) external {
        require(amount >= rate, "Minimum 100 USDT.z");
        require(usdtz.transferFrom(msg.sender, address(this), amount), "USDT.z transfer failed");
        uint256 outAmount = amount * 1e6 / rate;
        require(usdt.balanceOf(address(this)) >= outAmount, "Insufficient USDT liquidity");
        require(usdt.transfer(msg.sender, outAmount), "USDT transfer failed");
        emit Swapped(msg.sender, address(usdtz), address(usdt), amount, outAmount);
    }

    // Yalnız owner üçün çıxarış
    function withdraw(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).transfer(to, amount);
    }
}
