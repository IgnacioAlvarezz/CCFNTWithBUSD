// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../test/BUSDHarness.sol"; // Importa el contrato BUSD
import "../src/CCNFT.sol"; // Importa el contrato CCNFT

/// @title CCNFTTest
/// Contrato de prueba para el contrato CCNFT.
contract CCNFTTest is Test {
    address deployer; // Direccion del deployer, tambien el propietario del contrato
    address c1; // Cliente 1, un usuario para interactuar con el contrato
    address c2; // Cliente 2, otro usuario
    address funds; // Direccion simulada para el recolector de fondos
    address fees; // Direccion simulada para el recolector de tarifas
    BUSDHarness busd; // Instancia del contrato BUSD (token ERC20)
    CCNFT ccnft; // Instancia del contrato CCNFT (NFT)

    /// Funcion que se ejecuta antes de cada prueba.
    /// Inicializa las direcciones y despliega las instancias de BUSD y CCNFT.
    function setUp() public {
        // Asignar direcciones para las pruebas
        deployer = makeAddr("deployer");
        c1 = makeAddr("c1");
        c2 = makeAddr("c2");
        funds = makeAddr("fundsCollector");
        fees = makeAddr("feesCollector");

        // Inicia el "prank" para las acciones del deployer (incluyendo despliegues de contratos y llamadas solo para el propietario)
        vm.startPrank(deployer);

        busd = new BUSDHarness(); // Despliega el contrato BUSD (deployer es msg.sender)
        ccnft = new CCNFT("CollectibleCoinNFT", "CCNFT"); // Despliega el contrato CCNFT (deployer es msg.sender, por lo que el propietario de CCNFT es deployer)

        // DEBUG: Imprimir el propietario de CCNFT justo despues del despliegue
        console.log("CCNFT owner after deployment:", ccnft.owner());
        console.log("Expected deployer address:", deployer);

        // Configura el contrato CCNFT (todas estas llamadas ahora son realizadas por 'deployer')
        ccnft.setFundsToken(address(busd));
        ccnft.setFundsCollector(funds);
        ccnft.setFeesCollector(fees);
        ccnft.setCanBuy(true);
        ccnft.setCanClaim(true);
        ccnft.setCanTrade(true);
        ccnft.setMaxValueToRaise(type(uint256).max); // Usa el maximo uint256 para flexibilidad en las pruebas
        ccnft.addValidValues(100); // Agrega un valor valido predeterminado para probar la compra
        ccnft.setMaxBatchCount(10); // Establece un conteo de lote maximo razonable
        ccnft.setBuyFee(100); // 1%
        ccnft.setTradeFee(50); // 0.5%
        ccnft.setProfitToPay(0); // 0% de ganancia extra para el reclamo por simplicidad

        // Acuñar BUSD a los clientes para que puedan realizar compras (el deployer es el propietario de BUSD y llama a mint)
        busd.mint(c1, 1000 * 10 ** busd.decimals());
        busd.mint(c2, 1000 * 10 ** busd.decimals());
        busd.mint(funds, 1 * 10 ** busd.decimals());

        vm.stopPrank(); // Detiene el "prank" del deployer

        // Aprobar el gasto de BUSD por parte de CCNFT para c1 y c2 (estos son "pranks" separados)
        vm.prank(c1);
        busd.approve(address(ccnft), type(uint256).max);
        vm.prank(c2);
        busd.approve(address(ccnft), type(uint256).max);
    }

    /// Prueba del setter `setFundsCollector` del contrato CCNFT.
    /// Llama al metodo y luego verifica que el valor se haya establecido correctamente.
    function testSetFundsCollector() public {
        vm.prank(deployer);
        ccnft.setFundsCollector(funds);
        assertEq(ccnft.fundsCollector(), funds, "Funds collector not set correctly");
    }

    /// Prueba del setter `setFeesCollector` del contrato CCNFT.
    /// Verifica que el valor se haya establecido correctamente.
    function testSetFeesCollector() public {
        vm.prank(deployer);
        ccnft.setFeesCollector(fees);
        assertEq(ccnft.feesCollector(), fees, "Fees collector not set correctly");
    }

    /// Prueba del setter `setProfitToPay` del contrato CCNFT.
    /// Verifica que el valor se haya establecido correctamente.
    function testSetProfitToPay() public {
        uint32 newProfitToPay = 500; // 5%
        vm.prank(deployer);
        ccnft.setProfitToPay(newProfitToPay);
        assertEq(ccnft.profitToPay(), newProfitToPay, "Profit to pay not set correctly");
    }

    /// Prueba del setter `setCanBuy`:
    /// 1. Estableciendolo en `true` y verificando.
    /// 2. Despues establecerlo en `false` verificando nuevamente.
    function testSetCanBuy() public {
        // Probar establecer en true
        vm.prank(deployer);
        ccnft.setCanBuy(true);
        assertTrue(ccnft.canBuy(), "CanBuy should be true");

        // Probar establecer en false
        vm.prank(deployer);
        ccnft.setCanBuy(false);
        assertFalse(ccnft.canBuy(), "CanBuy should be false");
    }

    /// Prueba del setter `setCanTrade`. Similar a `testSetCanBuy`.
    function testSetCanTrade() public {
        // Probar establecer en true
        vm.prank(deployer);
        ccnft.setCanTrade(true);
        assertTrue(ccnft.canTrade(), "CanTrade should be true");

        // Probar establecer en false
        vm.prank(deployer);
        ccnft.setCanTrade(false);
        assertFalse(ccnft.canTrade(), "CanTrade should be false");
    }

    /// Prueba del setter `setCanClaim`. Similar a `testSetCanBuy`.
    function testSetCanClaim() public {
        // Probar establecer en true
        vm.prank(deployer);
        ccnft.setCanClaim(true);
        assertTrue(ccnft.canClaim(), "CanClaim should be true");

        // Probar establecer en false
        vm.prank(deployer);
        ccnft.setCanClaim(false);
        assertFalse(ccnft.canClaim(), "CanClaim should be false");
    }

    /// Prueba del setter `setMaxValueToRaise` con diferentes valores.
    /// Verifica que se establezcan correctamente.
    function testSetMaxValueToRaise() public {
        uint256 value1 = 1000 ether;
        vm.prank(deployer);
        ccnft.setMaxValueToRaise(value1);
        assertEq(ccnft.maxValueToRaise(), value1, "Max value to raise 1 not set correctly");

        uint256 value2 = 5000 ether;
        vm.prank(deployer);
        ccnft.setMaxValueToRaise(value2);
        assertEq(ccnft.maxValueToRaise(), value2, "Max value to raise 2 not set correctly");
    }

    /// Prueba del setter `addValidValues` añadiendo diferentes valores.
    /// Verifica que se hayan añadido correctamente.
    function testAddValidValues() public {
        vm.prank(deployer);
        ccnft.addValidValues(100);
        assertTrue(ccnft.validValues(100), "Value 100 should be valid");

        vm.prank(deployer);
        ccnft.addValidValues(200);
        assertTrue(ccnft.validValues(200), "Value 200 should be valid");

        assertFalse(ccnft.validValues(50), "Value 50 should not be valid"); // Verifica que otros valores no se añaden
    }

    /// Prueba del setter `setMaxBatchCount`.
    /// Verifica que el valor se haya establecido correctamente.
    function testSetMaxBatchCount() public {
        uint16 newMaxBatchCount = 5;
        vm.prank(deployer);
        ccnft.setMaxBatchCount(newMaxBatchCount);
        assertEq(ccnft.maxBatchCount(), newMaxBatchCount, "Max batch count not set correctly");
    }

    /// Prueba del setter `setBuyFee`.
    /// Verifica que el valor se haya establecido correctamente.
    function testSetBuyFee() public {
        uint16 newBuyFee = 250; // 2.5%
        vm.prank(deployer);
        ccnft.setBuyFee(newBuyFee);
        assertEq(ccnft.buyFee(), newBuyFee, "Buy fee not set correctly");
    }

    /// Prueba del setter `setTradeFee`.
    /// Verifica que el valor se haya establecido correctamente.
    function testSetTradeFee() public {
        uint16 newTradeFee = 100; // 1%
        vm.prank(deployer);
        ccnft.setTradeFee(newTradeFee);
        assertEq(ccnft.tradeFee(), newTradeFee, "Trade fee not set correctly");
    }

    /// Prueba de que no se pueda comerciar cuando canTrade es false.
    /// Verifica que se lance un error esperado.
    function testCannotTradeWhenCanTradeIsFalse() public {
        vm.startPrank(deployer);

        // Intentar llamar a trade (se necesita un tokenId existente para llegar al require correcto)
        // Para esto, primero necesitamos mintear un token y ponerlo en venta
        ccnft.setCanBuy(true);
        ccnft.addValidValues(100);
        ccnft.setMaxBatchCount(1);
        vm.stopPrank();

        vm.startPrank(c1); // Prank para que c1 compre y ponga en venta
        ccnft.buy(100, 1); // c1 compra un NFT (tokenId 0)
        ccnft.putOnSale(0, 100); // c1 pone el NFT en venta
        vm.stopPrank();

        // Asegurarse de que canTrade sea false (necesitamos canTrade for ccnft.putOnSale en paso anterior)
        vm.prank(deployer);
        ccnft.setCanTrade(false);
        vm.stopPrank();

        // Intentar comerciar con canTrade = false
        vm.prank(c2);
        vm.expectRevert("Trading is not allowed");
        ccnft.trade(0);
    }

    /// Prueba que no se pueda comerciar con un token que no existe, incluso si canTrade es true.
    /// Verifica que se lance un error esperado.
    function testCannotTradeWhenTokenDoesNotExist() public {
        // Asegurarse de que canTrade sea true
        vm.prank(deployer);
        ccnft.setCanTrade(true);

        // Intentar comerciar con un tokenId que no existe
        vm.prank(c1);
        vm.expectRevert("Token does not exist");
        ccnft.trade(999); // TokenId 999 no existe
    }

    /// Prueba que el comprador no pueda ser el vendedor.
    function testCannotTradeIfBuyerIsSeller() public {
        // Configurar para poder comprar y comerciar
        vm.startPrank(deployer); // Inicia el "prank" para las acciones del deployer
        ccnft.setCanBuy(true);
        ccnft.setCanTrade(true);
        ccnft.addValidValues(100);
        ccnft.setMaxBatchCount(1);
        vm.stopPrank(); // Detiene el "prank" del deployer

        // c1 compra un NFT
        vm.prank(c1);
        ccnft.buy(100, 1); // c1 compra tokenId 0

        // c1 intenta poner su propio NFT en venta
        vm.prank(c1);
        ccnft.putOnSale(0, 100);

        // c1 intenta comerciar su propio NFT
        vm.prank(c1);
        vm.expectRevert("Buyer is the Seller");
        ccnft.trade(0);
    }

    /// Prueba del flujo completo de compra, venta y reclamo de un NFT.
    function testFullNFTLifecycle() public {
        // Configuracion inicial
        vm.startPrank(deployer);
        ccnft.setCanBuy(true);
        ccnft.setCanClaim(true);
        ccnft.setCanTrade(true);
        ccnft.addValidValues(100);
        ccnft.setMaxBatchCount(1);
        ccnft.setFundsCollector(funds);
        ccnft.setFeesCollector(fees);
        ccnft.setMaxValueToRaise(1000 ether);
        ccnft.setBuyFee(100); // 1%
        ccnft.setTradeFee(50); // 0.5%
        ccnft.setProfitToPay(1000); // 10%
        vm.stopPrank(); // Detiene el "prank" del deployer

        uint256 initialC1BUSD = busd.balanceOf(c1);
        uint256 initialFundsBUSD = busd.balanceOf(funds);
        uint256 initialFeesBUSD = busd.balanceOf(fees);

        uint256 nftValue = 100; // Valor del NFT
        uint256 buyAmount = 1;

        // --- 1. Compra de NFT ---
        vm.prank(c1);
        ccnft.buy(nftValue, buyAmount);

        // Verificaciones despues de la compra
        assertEq(ccnft.balanceOf(c1), 1, "c1 should own 1 NFT");
        assertEq(ccnft.ownerOf(0), c1, "c1 should own tokenId 0");
        assertEq(ccnft.values(0), nftValue, "NFT value should be 100");
        assertEq(ccnft.totalValue(), nftValue, "Total value should be 100");

        uint256 buyFeeAmount = (nftValue * buyAmount * ccnft.buyFee()) / 10000;
        assertEq(
            busd.balanceOf(c1),
            initialC1BUSD - (nftValue * buyAmount) - buyFeeAmount,
            "c1 BUSD balance incorrect after buy"
        );
        assertEq(
            busd.balanceOf(funds),
            initialFundsBUSD + (nftValue * buyAmount),
            "Funds collector BUSD balance incorrect after buy"
        );
        assertEq(
            busd.balanceOf(fees), initialFeesBUSD + buyFeeAmount, "Fees collector BUSD balance incorrect after buy"
        );

        initialC1BUSD = busd.balanceOf(c1); // Actualizar balance de c1 para el comercio
        initialFundsBUSD = busd.balanceOf(funds); // No se espera cambio en fondos durante comercio
        initialFeesBUSD = busd.balanceOf(fees); // Actualizar balance de tarifas para el comercio

        // --- 2. Poner en Venta ---
        uint256 salePrice = 150;
        vm.prank(c1);
        ccnft.putOnSale(0, salePrice);

        (bool onSale, uint256 price) = ccnft.tokensOnSale(0);
        assertTrue(onSale, "Token 0 should be on sale");
        assertEq(price, salePrice, "Token 0 sale price incorrect");
        assertEq(ccnft.getListTokensOnSale().length, 1, "listTokensOnSale should have 1 token");
        assertEq(ccnft.getListTokensOnSale()[0], 0, "Token 0 should be in listTokensOnSale");

        // --- 3. Comercio (Trade) ---
        uint256 initialC2BUSD = busd.balanceOf(c2);
        vm.prank(c2);
        ccnft.trade(0);

        // Verificaciones despues del comercio
        assertEq(ccnft.ownerOf(0), c2, "c2 should now own tokenId 0");
        assertEq(ccnft.balanceOf(c1), 0, "c1 should not own any NFT");
        assertEq(ccnft.balanceOf(c2), 1, "c2 should own 1 NFT");

        (bool onSaleAfterTrade, uint256 priceAfterTrade) = ccnft.tokensOnSale(0);
        assertFalse(onSaleAfterTrade, "Token 0 should not be on sale after trade");
        assertEq(priceAfterTrade, 0, "Token 0 sale price should be reset");
        assertEq(ccnft.getListTokensOnSale().length, 0, "listTokensOnSale should be empty after trade");

        uint256 tradeFeeAmount = (nftValue * ccnft.tradeFee()) / 10000; // La tarifa se basa en el valor original del NFT
        assertEq(
            busd.balanceOf(c2), initialC2BUSD - salePrice - tradeFeeAmount, "c2 BUSD balance incorrect after trade"
        );
        assertEq(
            busd.balanceOf(c1), initialC1BUSD + salePrice, "c1 BUSD balance incorrect after trade (received sale price)"
        );
        assertEq(
            busd.balanceOf(fees), initialFeesBUSD + tradeFeeAmount, "Fees collector BUSD balance incorrect after trade"
        );

        initialC2BUSD = busd.balanceOf(c2); // Actualizar balance de c2 para el reclamo
        initialFundsBUSD = busd.balanceOf(funds); // Actualizar balance de fondos para el reclamo
        initialFeesBUSD = busd.balanceOf(fees); // Actualizar balance de tarifas para el reclamo (no deberia cambiar aqui)

        // --- 4. Reclamo (Claim) ---
        vm.prank(funds);
        busd.approve(address(ccnft), type(uint256).max);

        vm.startPrank(c2);
        console.log("Claimer is:", c2);
        console.log("Owner of tokenId 0 before claim:", ccnft.ownerOf(0)); // DEBUG
        ccnft.claim(new uint256[](1));

        // Verificaciones despues del reclamo
        assertEq(ccnft.balanceOf(c2), 0, "c2 should own 0 NFT after claim");
        vm.expectRevert("ERC721: invalid token ID");
        ccnft.ownerOf(0); // Verifica que el tokenId 0 ya no exista
        assertEq(ccnft.values(0), 0, "NFT value should be 0 after claim");
        assertEq(ccnft.totalValue(), 0, "Total value should be 0 after claim");

        uint256 profitAmount = (nftValue * ccnft.profitToPay()) / 10000;
        assertEq(busd.balanceOf(c2), initialC2BUSD + nftValue + profitAmount, "c2 BUSD balance incorrect after claim");
        assertEq(
            busd.balanceOf(funds),
            initialFundsBUSD - (nftValue + profitAmount),
            "Funds collector BUSD balance incorrect after claim"
        );
        vm.stopPrank();
    }
}
