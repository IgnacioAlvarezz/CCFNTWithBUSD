// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19; // Asegúrate de que esta versión coincida con tu foundry.toml y CCNFT.sol

import "forge-std/Script.sol";
import "../src/CCNFT.sol"; // Importa tu contrato CCNFT

/// @title DeployCCNFT
/// @dev Script de despliegue para el contrato CCNFT.
///      Este script obtiene la clave privada del entorno y despliega el contrato CCNFT.
contract DeployCCNFT is Script {
    /// @dev Función principal del script de despliegue.
    ///      Se ejecuta cuando usas `forge script ... --broadcast`.
    /// @return ccnft La instancia del contrato CCNFT desplegado.
    function run() public returns (CCNFT ccnft) {
        // Obtiene la clave privada del entorno.
        // Asegúrate de que `PRIVATE_KEY` esté configurada en tu archivo `.env`
        // o pasada como variable de entorno al ejecutar `forge script`.
        uint256 deployerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");

        // Inicia el proceso de envío de transacciones a la red.
        // Todas las operaciones subsiguientes realizadas por el "deployer"
        // serán parte de una transacción broadcast.
        vm.startBroadcast(deployerPrivateKey);

        // Despliega el contrato CCNFT.
        // Asegúrate de que los parámetros del constructor coincidan con tu `CCNFT.sol`.
        // En este caso, son `name_` y `symbol_`.
        ccnft = new CCNFT("MyCoolCollectibleNFT", "MCC");

        // Detiene el proceso de envío de transacciones.
        vm.stopBroadcast();

        // Imprime la dirección del contrato desplegado en la consola.
        console.log("CCNFT contrato desplegado en:", address(ccnft));
    }
}
