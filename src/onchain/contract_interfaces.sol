pragma solidity >=0.4.21 <0.6.0;

contract SecretRequester {

    SecretHolder secret_holder;
    constructor(SecretHolder sh) internal {
        secret_holder = sh;
        secret_holder.registerRequester();
    }
    modifier isFromHolder(){
        require(msg.sender == address(secret_holder), "Answer from unkown holder");
        _;
    }

    function callback(uint id, uint output) public isFromHolder(){
        handleAnswer(id, output);
    }
    function handleAnswer(uint id, uint output) internal;
}

contract SecretHolder {

    SecretRequester requester;
    bool is_registered;
    uint private id_counter;

    constructor() public{
        id_counter = 0;
    }

    function registerRequester() public {
        require(!is_registered, "A requester was already registered");
        requester = SecretRequester(msg.sender);
        is_registered = true;
    }
    modifier isFromRequester(){
        require(is_registered, "No requester was registered");
        require(msg.sender == address(requester), "Request from unkown requester");
        _;
    }
    function requestComputation(uint input)
        public
        payable
        isFromRequester()
    returns (uint){
        uint id = id_counter;
        id_counter++;
        makeComputation(id, input);
        return id;
    }
    function makeComputation(uint id, uint input) internal;
}

contract OnChainSecretHolder is SecretHolder {
    uint private secret;
    constructor(uint secret_value) internal{
        secret = secret_value;
    }
    function makeComputation(uint id, uint input) internal{
        uint output = computation(secret, input);
        requester.callback(id, output);
    }
    function computation(uint secret_input, uint input) internal returns (uint);
}

contract OffChainSecretHolder is SecretHolder {
    bytes private commitment;
    bytes public verification_data;
    struct request {
        uint input;
        uint reward;
        bool active;
    }
    mapping(uint => request) private requests;
    event NewRequest(uint id, uint input, uint reward);
    event NewAnswer(uint id, uint input, uint output);

    constructor(bytes memory commitment_value, bytes memory verification_data_value) public{
        commitment = commitment_value;
        verification_data = verification_data_value;
    }

    function makeComputation(uint id, uint input) internal {
        requests[id] = request(input, msg.value, true);
        emit NewRequest(id, input, msg.value);
    }

    function answerRequest(uint id, uint output, bytes memory proof) public{
        require(requests[id].active, "The answer wasn't needed");
        require(verifyProof(requests[id].input, output, proof), "The proof was incorrect");
        emit NewAnswer(id, requests[id].input, output);
        requester.callback(id, output);
        msg.sender.transfer(requests[id].reward);
    }

    function verifyProof(uint input, uint output, bytes memory proof) internal returns (bool);
}