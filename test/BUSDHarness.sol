// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {BUSD} from "../src/BUSD.sol";
import {console} from "forge-std/console.sol";

contract BUSDHarness is BUSD {
    /// @dev Minta tokens a la dirección especificada.
    /// @param to Dirección a la que se enviarán los tokens.
    /// @param amount Cantidad de tokens a enviar.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
        console.log("Minted %s BUSD to %s", amount, to);
    }
}
