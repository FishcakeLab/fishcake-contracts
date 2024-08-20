// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {console} from "forge-std/console.sol";

import {FishcakeTestHelperTest} from "../../FishcakeTestHelper.t.sol";
import {FishCakeCoin} from "@contracts/core/token/FishCakeCoin.sol";

//forge test --match-path test/core/token/FishCakeCoin.t.sol
contract FishCakeCoinTest is FishcakeTestHelperTest {

    function setUp() public virtual override {
        super.setUp();
    }

    function test_PoolAllocate() public {
        FishCakeCoin tempFishCakeCoin = FishCakeCoin(address(proxyFishCakeCoin));

        test_FishCakeCoin_PoolAllocate();

        uint256 before_burn_totalSupply = tempFishCakeCoin.totalSupply();
        uint256 before_burn_balance = tempFishCakeCoin.FccBalance(address(proxyDirectSalePool));

        vm.startPrank(address(redemptionPool));
        tempFishCakeCoin.burn(address(proxyDirectSalePool), 1000);
        vm.stopPrank();

        uint256 after_burn_totalSupply = tempFishCakeCoin.totalSupply();
        console.log("FishCakeCoin test_PoolAllocate totalSupply:", tempFishCakeCoin.totalSupply());
        assertTrue(before_burn_totalSupply - 1000 == after_burn_totalSupply, "before_burn_totalSupply - 1000 == after_burn_totalSupply");

        uint256 after_burn_balance = tempFishCakeCoin.FccBalance(address(proxyDirectSalePool));
        assertTrue((before_burn_balance - 1000) == after_burn_balance, "(before_burn_balance - 1000) == after_burn_balance");
        console.log("FishCakeCoin test_PoolAllocate after_burn_balance:", after_burn_balance);
    }

    function test_call_two() public {
        super.test_FishCakeCoin_PoolAllocate();

        try this.externalTest_FishCakeCoin_PoolAllocate() {
            assertTrue(false, "If the program runs to this line, it is abnormal");
        } catch {
            assertTrue(true, "If the program runs to this line, it is normal");
            console.log("FishcakeDeployer setUp: success");
        }
    }

    function externalTest_FishCakeCoin_PoolAllocate() external {
        // 将原来的逻辑移到这里
        super.test_FishCakeCoin_PoolAllocate();
    }

}
