// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

/// @title CCNFT
/// @dev Contrato de un Token No Fungible (NFT) personalizado que hereda de ERC721Enumerable, Ownable y ReentrancyGuard.
///      Incorpora funcionalidades de compra, reclamo, comercio y gestión de tarifas.
contract CCNFT is ERC721Enumerable, Ownable, ReentrancyGuard {
    // EVENTOS
    // indexed: Permiten realizar búsquedas en los registros de eventos.

    /// @dev Evento emitido cuando se compra un NFT.
    /// @param buyer La dirección del comprador.
    /// @param tokenId El ID único del NFT comprado.
    /// @param value El valor asociado al NFT comprado.
    event Buy(address indexed buyer, uint256 indexed tokenId, uint256 value);

    /// @dev Evento emitido cuando un usuario reclama (quema) un NFT.
    /// @param claimer La dirección del usuario que reclama los NFTs.
    /// @param tokenId El ID único del NFT reclamado.
    event Claim(address indexed claimer, uint256 indexed tokenId);

    /// @dev Evento emitido cuando se transfiere un NFT de un usuario a otro (comercio).
    /// @param buyer La dirección del comprador del NFT.
    /// @param seller La dirección del vendedor del NFT.
    /// @param tokenId El ID único del NFT que se transfiere.
    /// @param value El valor pagado por el comprador al vendedor por el NFT.
    event Trade(address indexed buyer, address indexed seller, uint256 indexed tokenId, uint256 value);

    /// @dev Evento emitido cuando un NFT se pone en venta.
    /// @param tokenId El ID único del NFT que se pone en venta.
    /// @param price El precio al cual se pone en venta el NFT.
    event PutOnSale(uint256 indexed tokenId, uint256 price);

    /// @dev Estructura del estado de venta de un NFT.
    struct TokenSale {
        // Indicamos si el NFT está en venta.
        bool onSale;
        // Indicamos el precio del NFT si está en venta.
        uint256 price;
    }

    // Biblioteca Counters de OpenZeppelin para manejar contadores de manera segura.
    using Counters for Counters.Counter;

    // Contador para asignar IDs únicos a cada NFT que se crea.
    Counters.Counter private tokenIdTracker;

    // Mapeo del ID de un token (NFT) a un valor específico.
    mapping(uint256 => uint256) public values;

    // Mapeo de un valor a un booleano para indicar si el valor es válido o no.
    mapping(uint256 => bool) public validValues;

    // Mapeo del ID de un token (NFT) a su estado de venta (TokenSale).
    mapping(uint256 => TokenSale) public tokensOnSale;

    // Lista que contiene los IDs de los NFTs que están actualmente en venta.
    uint256[] public listTokensOnSale;

    address public fundsCollector; // Dirección de los fondos de las ventas de los NFTs
    address public feesCollector; // Dirección de las tarifas de transacción (compra y venta de los NFTs)

    bool public canBuy; // Booleano que indica si las compras de NFTs están permitidas.
    bool public canClaim; // Booleano que indica si la reclamación (quitar) de NFTs está permitida.
    bool public canTrade; // Booleano que indica si la transferencia de NFTs está permitida.

    uint256 public totalValue; // Valor total acumulado de todos los NFTs en circulación.
    uint256 public maxValueToRaise; // Valor máximo permitido para recaudar a través de compras de NFTs.

    uint16 public buyFee; // Tarifa aplicada a las compras de NFTs.
    uint16 public tradeFee; // Tarifa aplicada a las transferencias de NFTs.

    uint16 public maxBatchCount; // Límite en la cantidad de NFTs por operación (evitar exceder el límite de gas en una transacción).

    uint32 public profitToPay; // Porcentaje adicional a pagar en las reclamaciones.

    // Referencia al contrato ERC20 manejador de fondos.
    IERC20 public fundsToken;

    /// @dev Constructor del contrato.
    /// @param name_ El nombre del token ERC721.
    /// @param symbol_ El símbolo del token ERC721.
    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) Ownable() {
        // El constructor está vacío ya que los parámetros se pasan a los contratos base.
        // Se pueden inicializar otras variables aquí si es necesario.
    }

    // PUBLIC FUNCTIONS

    /// @dev Función de compra de NFTs.
    /// @param value El valor de cada NFT que se está comprando.
    /// @param amount La cantidad de NFTs que se quieren comprar.
    function buy(uint256 value, uint256 amount) external nonReentrant {
        // Verificación de permisos de la compra con "canBuy".
        require(canBuy, "Purchases are not allowed");

        // Verificación de la cantidad de NFTs a comprar sea mayor que 0 y menor o igual al máximo permitido (maxBatchCount).
        require(amount > 0 && amount <= maxBatchCount, "Invalid amount: must be > 0 and <= maxBatchCount");

        // Verificación del valor especificado para los NFTs según los valores permitidos en validValues.
        require(validValues[value], "Invalid NFT value: value not in validValues");

        // Verificación del valor total después de la compra (no debe exceder el valor máximo permitido "maxValueToRaise").
        require(totalValue + (value * amount) <= maxValueToRaise, "Max value to raise exceeded");

        totalValue += value * amount; // Incremento del valor total acumulado por el valor de los NFTs comprados.

        // Bucle para mintear la cantidad especificada de NFTs.
        for (uint256 i = 0; i < amount; i++) {
            values[tokenIdTracker.current()] = value; // Asignar el valor del NFT al tokenId actual en el mapeo values.
            _safeMint(_msgSender(), tokenIdTracker.current()); // Minteo de NFT y asignación al msg.sender.
            emit Buy(_msgSender(), tokenIdTracker.current(), value); // Evento Buy con el comprador, el tokenId y el valor del NFT.
            tokenIdTracker.increment(); // Incremento del contador tokenIdTracker (NFT deben tener un tokenId único).
        }

        // Transfencia de fondos desde el comprador (_msgSender()) al recolector de fondos (fundsCollector) por el valor total de los NFTs comprados.
        // Se usa `value * amount` para el total de la compra.
        if (!fundsToken.transferFrom(_msgSender(), fundsCollector, value * amount)) {
            revert("Cannot send funds tokens"); // Mensaje de falla.
        }

        // Transferencia de tarifas de compra desde el comprador (_msgSender()) al recolector de tarifas (feesCollector).
        // Tarifa = fracción del valor total de la compra (value * amount * buyFee / 10000).
        if (!fundsToken.transferFrom(_msgSender(), feesCollector, (value * amount * buyFee) / 10000)) {
            revert("Cannot send fees tokens"); // Mensaje de falla.
        }
    }

    /// @dev Función de "reclamo" de NFTs. Esto implica quemar los tokens y recuperar su valor.
    /// @param listTokenId Lista de IDs de tokens de reclamo (utilizar calldata para eficiencia).
    function claim(uint256[] calldata listTokenId) external nonReentrant {
        // Verificación habilitación de "reclamo" (canClaim).
        require(canClaim, "Claiming is not allowed");

        // Verificación de la cantidad de tokens a reclamar (mayor que 0 y menor o igual a maxBatchCount).
        require(listTokenId.length > 0 && listTokenId.length <= maxBatchCount, "Invalid amount of tokens to claim");

        uint256 claimValue = 0; // Inicializacion de claimValue a 0.
        TokenSale storage tokenSale; // Variable tokenSale.

        // Bucle para iterar a través de cada token ID en listTokenId.
        for (uint256 i = 0; i < listTokenId.length; i++) {
            // Verificación listTokenId[i] exista.
            require(_exists(listTokenId[i]), "Token does not exist");

            // Verificación que _msgSender() sea el propietario del token.
            require(ownerOf(listTokenId[i]) == _msgSender(), "Only owner can claim this token");

            claimValue += values[listTokenId[i]]; // Suma de el valor del token al claimValue acumulado.
            values[listTokenId[i]] = 0; // Reseteo del valor del token a 0.

            tokenSale = tokensOnSale[listTokenId[i]]; // Acceso a la información de venta del token
            tokenSale.onSale = false; // Desactivacion del estado de venta.
            tokenSale.price = 0; // Reseteo del precio de venta.

            _removeFromArray(listTokensOnSale, listTokenId[i]); // Remover el token de la lista de tokens en venta.
            _burn(listTokenId[i]); // Quemar el token, eliminándolo permanentemente de la circulación.
            emit Claim(_msgSender(), listTokenId[i]); // Registrar el ID y propietario del token reclamado.
        }
        totalValue -= claimValue; // Reducir el totalValue acumulado.

        // Calculo del monto total a transferir (claimValue + (claimValue * profitToPay / 10000)).
        // Transferir los fondos desde fundsCollector al (_msgSender()).
        // Se usa `claimValue` ya que es el valor total de los NFTs reclamados.
        if (!fundsToken.transferFrom(fundsCollector, _msgSender(), claimValue + (claimValue * profitToPay / 10000))) {
            revert("Cannot send funds for claim"); // Mensaje de falla.
        }
    }

    /// @dev Función de compra de NFT que esta en venta.
    /// @param tokenId El ID del token a comerciar.
    function trade(uint256 tokenId) external nonReentrant {
        // Verificación del comercio de NFTs (canTrade).
        require(canTrade, "Trading is not allowed");
        // Verificación de existencia del tokenId (_exists).
        require(_exists(tokenId), "Token does not exist");
        // Verificamos que el comprador (el que llama a la función) no sea el propietario actual del NFT.
        require(ownerOf(tokenId) != _msgSender(), "Buyer is the Seller");

        TokenSale storage tokenSale = tokensOnSale[tokenId]; // Estado de venta del NFT.

        // Verifica que el NFT esté actualmente en venta (onSale es true).
        require(tokenSale.onSale, "Token not On Sale");

        // Transferencia del precio de venta del comprador al propietario actual del NFT usando fundsToken.
        if (!fundsToken.transferFrom(_msgSender(), ownerOf(tokenId), tokenSale.price)) {
            revert("Cannot send funds to seller"); // Mensaje de falla.
        }

        // Transferencia de tarifa de comercio (calculada como un porcentaje del valor original del NFT) del comprador al feesCollector.
        if (!fundsToken.transferFrom(_msgSender(), feesCollector, (values[tokenId] * tradeFee) / 10000)) {
            revert("Cannot send fees tokens"); // Mensaje de falla.
        }

        emit Trade(_msgSender(), ownerOf(tokenId), tokenId, tokenSale.price); // Registro de dirección del comprador, dirección del vendedor, tokenId, y precio de venta.

        _safeTransfer(ownerOf(tokenId), _msgSender(), tokenId, ""); // Transferencia del NFT del propietario actual al comprador.

        tokenSale.onSale = false; // NFT no disponible para la venta.
        tokenSale.price = 0; // Reseteo del precio de venta del NFT.
        _removeFromArray(listTokensOnSale, tokenId); // Remover el tokenId de la lista listTokensOnSale de NFTs.
    }

    /// @dev Función para poner en venta un NFT.
    /// @param tokenId El ID del token a poner en venta.
    /// @param price El precio al que se venderá el token.
    function putOnSale(uint256 tokenId, uint256 price) external {
        // Verificación de operaciones de comercio (canTrade).
        require(canTrade, "Trading is not allowed");

        // Verificación de existencia del tokenId mediante "_exists".
        require(_exists(tokenId), "Token does not exist");

        // Verificación remitente de la transacción es propietario del token.
        require(ownerOf(tokenId) == _msgSender(), "Only owner can put token on sale");

        TokenSale storage tokenSale = tokensOnSale[tokenId]; // Variable de almacenamiento de datos para el token.

        tokenSale.onSale = true; // Indicar que el token está en venta.
        tokenSale.price = price; // Indicar precio de venta del token.

        _addToArray(listTokensOnSale, tokenId); // Añadir token a la lista.

        emit PutOnSale(tokenId, price); // Notificar que el token ha sido puesto a la venta (token y precio).
    }

    // SETTERS

    /// @dev Utilización del token ERC20 para transacciones.
    /// @param token La dirección del contrato del token ERC20.
    function setFundsToken(address token) external onlyOwner {
        // La dirección no puede ser la dirección cero (address(0)).
        require(token != address(0), "Invalid funds token address");
        fundsToken = IERC20(token);
    }

    /// @dev Dirección para colectar los fondos de las ventas de NFTs.
    /// @param _address Dirección del colector de fondos.
    function setFundsCollector(address _address) external onlyOwner {
        // La dirección no puede ser la dirección cero (address(0))
        require(_address != address(0), "Invalid funds collector address");
        fundsCollector = _address;
    }

    /// @dev Dirección para colectar las tarifas de transacción.
    /// @param _address Dirección del colector de tarifas.
    function setFeesCollector(address _address) external onlyOwner {
        // La dirección no puede ser la dirección cero (address(0))
        require(_address != address(0), "Invalid fees collector address");
        feesCollector = _address;
    }

    /// @dev Porcentaje de beneficio a pagar en las reclamaciones.
    /// @param _profitToPay Porcentaje de beneficio a pagar.
    function setProfitToPay(uint32 _profitToPay) external onlyOwner {
        profitToPay = _profitToPay; // Asignar valor proporcionado a la variable profitToPay.
    }

    /// @dev Función que Habilita o deshabilita la compra de NFTs.
    /// @param _canBuy Booleano que indica si la compra está permitida.
    function setCanBuy(bool _canBuy) external onlyOwner {
        canBuy = _canBuy; // Asignar valor proporcionado a la variable canBuy.
    }

    /// @dev Función que Habilita o deshabilita la reclamación de NFTs.
    /// @param _canClaim Booleano que indica si la reclamacion está permitida.
    function setCanClaim(bool _canClaim) external onlyOwner {
        canClaim = _canClaim;
    }

    /// @dev Función que Habilita o deshabilita el intercambio de NFTs.
    /// @param _canTrade Booleano que indica si la intercambio está permitido.
    function setCanTrade(bool _canTrade) external onlyOwner {
        canTrade = _canTrade;
    }

    /// @dev Valor máximo que se puede recaudar de venta de NFTs.
    /// @param _maxValueToRaise Valor máximo a recaudar.
    function setMaxValueToRaise(uint256 _maxValueToRaise) external onlyOwner {
        maxValueToRaise = _maxValueToRaise; // Asignar valor proporcionado a la variable maxValueToRaise.
    }

    /// @dev Función para agregar un valor válido para NFTs.
    /// @param value Valor que se quiere agregar como válido.
    function addValidValues(uint256 value) external onlyOwner {
        validValues[value] = true; // Asignar valor como válido en el mapeo validValues.
    }

    /// @dev Función para establecer la cantidad máxima de NFTs por operación.
    /// @param _maxBatchCount Cantidad máxima de NFTs por operación.
    function setMaxBatchCount(uint16 _maxBatchCount) external onlyOwner {
        maxBatchCount = _maxBatchCount; // Asignar valor proporcionado a la variable maxBatchCount.
    }

    /// @dev Tarifa aplicada a las compras de NFTs.
    /// @param _buyFee Porcentaje de tarifa para compras.
    function setBuyFee(uint16 _buyFee) external onlyOwner {
        buyFee = _buyFee; // Asignar valor proporcionado a la variable buyFee.
    }

    /// @dev Tarifa aplicada a las transacciones de NFTs.
    /// @param _tradeFee Porcentaje de tarifa para transacciones.
    function setTradeFee(uint16 _tradeFee) external onlyOwner {
        tradeFee = _tradeFee; // Asignar valor proporcionado a la variable tradeFee.
    }

    // ARRAYS
    /// @dev Función para obtener cantidad de tokens en venta.
    /// @return Cantidad de tokens en venta.
    function getListTokensOnSale() external view returns (uint256[] memory) {
        return listTokensOnSale;
    }

    /// @dev Verificar duplicados en el array antes de agregar un nuevo valor.
    /// @param list Array de enteros donde se añadirá el valor.
    /// @param value Valor que se añadirá al array.
    function _addToArray(uint256[] storage list, uint256 value) private {
        // Posición del value en el array list usando la función _find.
        uint256 index = _find(list, value);
        if (index == list.length) {
            // Si el valor no está en el array, push al final del array.
            list.push(value);
        }
    }

    /// @dev Eliminar un valor del array.
    /// @param list Array de enteros del cual se eliminará el valor.
    /// @param value Valor que se eliminará al array.
    function _removeFromArray(uint256[] storage list, uint256 value) private {
        // Posición del value en el array list usando la función _find.
        uint256 index = _find(list, value);
        if (index < list.length) {
            // Si el valor está en el array, reemplazar el valor con el último valor en el array y despues reducir el tamaño del array.
            list[index] = list[list.length - 1];
            list.pop();
        }
    }

    /// @dev Buscar un valor en un array y retornar su índice o la longitud del array si no se encuentra.
    /// @param list Array de enteros en el cual se buscará el valor.
    /// @param value Valor que se buscará en el array.
    function _find(uint256[] storage list, uint256 value) private view returns (uint256) {
        for (uint256 i = 0; i < list.length; i++) {
            // Retornar la posición del valor en el array.
            if (list[i] == value) {
                return i;
            }
        }
        return list.length; // Si no se encuentra, retornar la longitud del array.
    }

    // NOT SUPPORTED FUNCTIONS

    /// @dev Funciones para deshabilitar las transferencias de NFTs estándar de ERC721.
    function transferFrom(address, address, uint256) public pure override(ERC721, IERC721) {
        revert("Not Allowed");
    }

    function safeTransferFrom(address, address, uint256) public pure override(ERC721, IERC721) {
        revert("Not Allowed");
    }

    function safeTransferFrom(address, address, uint256, bytes memory) public pure override(ERC721, IERC721) {
        revert("Not Allowed");
    }

    // Funciones para asegurar que el contrato cumple con los estándares requeridos por ERC721 y ERC721Enumerable.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}
