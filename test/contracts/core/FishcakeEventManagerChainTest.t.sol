// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "openzeppelin-foundry-upgrades/Upgrades.sol";
import {FishcakeEventManagerMultiChain} from "../../../src/contracts/core/FishcakeEventManagerMultiChain.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Simple mock token for testing
contract MockUSDT is ERC20 {
    constructor() ERC20("Mock USDT", "USDT") {}
    
    function decimals() public pure override returns (uint8) {
        return 6;
    }
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

/**
 * @title FishcakeEventManagerChainTest
 * @notice Basic tests for multichain event manager
 */
contract FishcakeEventManagerChainTest is Test {
    FishcakeEventManagerMultiChain public manager;
    MockUSDT public usdt;
    
    address owner = address(1);
    address creator = address(2);
    address user1 = address(3);

    function setUp() public {
        usdt = new MockUSDT();
        
        address proxy = Upgrades.deployTransparentProxy(
            "FishcakeEventManagerMultiChain.sol",
            owner,
            abi.encodeCall(
                FishcakeEventManagerMultiChain.initialize,
                (owner, address(usdt))
            )
        );
        
        manager = FishcakeEventManagerMultiChain(proxy);
        
        // Give creator some tokens
        usdt.mint(creator, 1000000e6);
        vm.prank(creator);
        usdt.approve(address(manager), type(uint256).max);
    }

    // Test basic initialization
    function testInit() public {
        assertEq(manager.owner(), owner);
        assertTrue(manager.supportedTokens(address(usdt)));
    }

    // Test creating a fixed reward activity
    function testCreateFixed() public {
        vm.prank(creator);
        (bool ok, uint256 id) = manager.createActivity(
            "Coffee Shop",
            "Free coffee",
            "NYC",
            block.timestamp + 7 days,
            100e6,
            FishcakeEventManagerMultiChain.DropType.FIXED,
            100,
            0,
            1e6,
            address(usdt)
        );
        
        assertTrue(ok);
        assertEq(id, 1);
    }

    // Test distributing rewards
    function testDistribute() public {
        // create activity
        vm.prank(creator);
        (, uint256 id) = manager.createActivity(
            "Test",
            "Desc",
            "Loc",
            block.timestamp + 7 days,
            100e6,
            FishcakeEventManagerMultiChain.DropType.FIXED,
            100,
            0,
            1e6,
            address(usdt)
        );
        
        // distribute to user
        vm.prank(creator);
        manager.distributeReward(id, user1, 1e6);
        
        assertEq(usdt.balanceOf(user1), 1e6);
        assertTrue(manager.hasUserReceived(id, user1));
    }

    // Test can't distribute twice
    function testCantDistributeTwice() public {
        vm.prank(creator);
        (, uint256 id) = manager.createActivity(
            "Test",
            "Desc",
            "Loc",
            block.timestamp + 7 days,
            100e6,
            FishcakeEventManagerMultiChain.DropType.FIXED,
            100,
            0,
            1e6,
            address(usdt)
        );
        
        vm.startPrank(creator);
        manager.distributeReward(id, user1, 1e6);
        
        vm.expectRevert("Already received reward");
        manager.distributeReward(id, user1, 1e6);
        vm.stopPrank();
    }

    // Test finishing activity returns remaining funds
    function testFinish() public {
        vm.prank(creator);
        (, uint256 id) = manager.createActivity(
            "Test",
            "Desc",
            "Loc",
            block.timestamp + 7 days,
            100e6,
            FishcakeEventManagerMultiChain.DropType.FIXED,
            100,
            0,
            1e6,
            address(usdt)
        );
        
        uint256 before = usdt.balanceOf(creator);
        
        vm.prank(creator);
        manager.finishActivity(id);
        
        // should get all funds back since we didn't distribute any
        assertEq(usdt.balanceOf(creator) - before, 100e6);
    }

    // Test random type activity
    function testRandom() public {
        vm.prank(creator);
        (bool ok, uint256 id) = manager.createActivity(
            "Lucky Draw",
            "Random",
            "NYC",
            block.timestamp + 7 days,
            500e6,
            FishcakeEventManagerMultiChain.DropType.RANDOM,
            50,
            5e6,
            20e6,
            address(usdt)
        );
        
        assertTrue(ok);
        
        // distribute random amount within range
        vm.prank(creator);
        manager.distributeReward(id, user1, 10e6);
        
        assertEq(usdt.balanceOf(user1), 10e6);
    }

    // Test verification
    function testVerify() public {
        vm.prank(creator);
        (, uint256 id) = manager.createActivity(
            "Test",
            "Desc",
            "Loc",
            block.timestamp + 7 days,
            100e6,
            FishcakeEventManagerMultiChain.DropType.FIXED,
            100,
            0,
            1e6,
            address(usdt)
        );
        
        (bool valid, string memory reason) = manager.verifyParticipant(id, user1);
        assertTrue(valid);
        assertEq(reason, "Eligible");
    }

    // Test pause functionality
    function testPause() public {
        vm.prank(owner);
        manager.pause();
        
        vm.prank(creator);
        vm.expectRevert();
        manager.createActivity(
            "Test",
            "Desc",
            "Loc",
            block.timestamp + 7 days,
            100e6,
            FishcakeEventManagerMultiChain.DropType.FIXED,
            100,
            0,
            1e6,
            address(usdt)
        );
    }

    // Test only creator can distribute
    function testOnlyCreator() public {
        vm.prank(creator);
        (, uint256 id) = manager.createActivity(
            "Test",
            "Desc",
            "Loc",
            block.timestamp + 7 days,
            100e6,
            FishcakeEventManagerMultiChain.DropType.FIXED,
            100,
            0,
            1e6,
            address(usdt)
        );
        
        vm.prank(user1);
        vm.expectRevert("Not the activity creator");
        manager.distributeReward(id, user1, 1e6);
    }
}