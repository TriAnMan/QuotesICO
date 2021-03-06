pragma solidity ^0.4.11;

contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract owned {
    address public owner;

    function owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract MyToken is owned {
    /* Public variables of the token */
    string public standard = 'Token 0.1';
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 amount);

    /* This notifies clients about the amount minted */
    event Mint(address indexed to, uint256 amount);

    event Redeem(address indexed toOwner, uint256 value);

    event Price(uint256 value);

    event Deadline(uint timestamp);

    uint public deadline;

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken(
        uint256 initialSupply,
        uint durationInHours,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
    ) {
        owner = msg.sender;
        balanceOf[this] = initialSupply;                    // Give the contract all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        buyPrice = 1 ether;
        deadline = now + durationInHours * 1 hours;
    }

    function mintToken(address target, uint256 mintedAmount) onlyOwner {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        Mint(target, mintedAmount);
    }

    uint256 public buyPrice;

    function setPrice(uint256 newBuyPriceInEther) onlyOwner {
        buyPrice = newBuyPriceInEther * 1 ether;
        Price(newBuyPriceInEther);
    }

    function prolong(uint durationInHours) onlyOwner {
        deadline += durationInHours * 1 hours;
        Deadline(deadline);
    }

    function () payable {
        require(now < deadline);
        uint amount = msg.value / buyPrice;                // calculates the amount
        require(amount >= 1);
        require(balanceOf[this] >= amount);                // checks if it has enough to sell
        balanceOf[msg.sender] += amount;                   // adds the amount to buyer's balance
        balanceOf[this] -= amount;                         // subtracts amount from seller's balance
        Transfer(this, msg.sender, amount);                // execute an event reflecting the change
    }

    function redeemEtherToOwner() onlyOwner {
        Redeem(owner, this.balance);
        owner.transfer(this.balance);
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        require(_to != 0x0);                                 // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[msg.sender] >= _value);            // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);  // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then communicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(_to != 0x0);                                  // Prevent transfer to 0x0 address. Use burn() instead
        require(balanceOf[_from] >= _value);                  // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);   // Check for overflows
        require(_value <= allowance[_from][msg.sender]);      // Check allowance
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);             // Check if the sender has enough
        balanceOf[msg.sender] -= _value;                      // Subtract from the sender
        totalSupply -= _value;                                // Updates totalSupply
        Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) returns (bool success) {
        require(balanceOf[_from] >= _value);                 // Check if the sender has enough
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        balanceOf[_from] -= _value;                          // Subtract from the sender
        totalSupply -= _value;                               // Updates totalSupply
        Burn(_from, _value);
        return true;
    }
}