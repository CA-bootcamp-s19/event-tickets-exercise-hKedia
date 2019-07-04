pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */
    mapping(uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier verifyIfOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent(string calldata _desc, string calldata _url, uint _noOfTickets)
    external
    verifyIfOwner
    returns(uint) {
        uint eventId = idGenerator;
        events[eventId] = Event({
            description: _desc,
            website: _url,
            totalTickets: _noOfTickets,
            sales: 0,
            isOpen: true
        });
        idGenerator += 1;
        emit LogEventAdded(_desc, _url, _noOfTickets, eventId);
        return eventId;
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _eventId)
    public
    view
    returns(string memory description, string memory website, uint totalTickets, uint sales, bool isOpen) {
        description = events[_eventId].description;
        website = events[_eventId].website;
        totalTickets = events[_eventId].totalTickets;
        sales = events[_eventId].sales;
        isOpen = events[_eventId].isOpen;
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _eventId, uint _noOfTickets) external payable {
        require(events[_eventId].isOpen, "Event is not Open");
        require(msg.value >= PRICE_TICKET * _noOfTickets, "Insufficient funds sent");
        require(events[_eventId].totalTickets >= events[_eventId].sales + _noOfTickets, "Not enough tickets");

        events[_eventId].buyers[msg.sender] += _noOfTickets;
        events[_eventId].sales += _noOfTickets;

        if(msg.value > PRICE_TICKET * _noOfTickets) {
            uint change = msg.value - (PRICE_TICKET * _noOfTickets);
            msg.sender.transfer(change);
        }

        emit LogBuyTickets(msg.sender, _eventId, _noOfTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _eventId) external payable {
        require(events[_eventId].isOpen, "Sorry, event is closed");
        require(events[_eventId].buyers[msg.sender] > 0, "No Tickets purchased for this event");
        uint noOfTickets = events[_eventId].buyers[msg.sender];
        events[_eventId].buyers[msg.sender] = 0;
        events[_eventId].sales -= noOfTickets;
        msg.sender.transfer(PRICE_TICKET * noOfTickets);
        emit LogGetRefund(msg.sender, _eventId, noOfTickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _eventId) public view returns(uint) {
        return events[_eventId].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
    function endSale(uint _eventId) external verifyIfOwner {
        events[_eventId].isOpen = false;
        uint totalSales = events[_eventId].sales * PRICE_TICKET;
        owner.transfer(totalSales);
        emit LogEndSale(msg.sender, totalSales, _eventId);
    }
}
