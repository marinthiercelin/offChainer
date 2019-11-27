pragma solidity >=0.4.21 <0.6.0;
import "../interfaces.sol";

interface Verifier {
    function verifyTx(
            uint[2] calldata a,
            uint[2][2] calldata b,
            uint[2] calldata c,
            uint[4] calldata input
        ) external returns (bool r);
}


contract ZokratesOffChainHolder is OffChainSecretHolder {

    event ProofCheck(string message);

    uint[2] public commitment;
    Verifier public verifier_contract;
    string private verifyTxSignature = "verifyTx(uint256[2],uint256[2][2],uint256[2],uint256[4])";

    constructor(uint[2] memory commitment_value, address verifier_contract_address) public{
        commitment = commitment_value;
        verifier_contract = Verifier(verifier_contract_address);
    }

    struct Proof{
        uint[2] a;
        uint[2][2] b;
        uint[2] c;
    }

    // We always return true, hence the computation is unverified
    function verifyProof(uint input, uint output, bytes memory proof) internal returns (bool){
        Proof memory proof_struct = castProof(proof);
        uint[4] memory verifier_inputs;
        verifier_inputs[0] = input;
        verifier_inputs[0] = commitment[0];
        verifier_inputs[0] = commitment[1];
        verifier_inputs[0] = output;
        // bytes memory payload = abi.encodeWithSignature(verifyTxSignature, proof_struct.a, proof_struct.b, proof_struct.c, verifier_inputs);
        // (bool success, bytes memory returnData) = verifier_contract.call(payload);
        // require(success, "The verification method failed");
        // require(returnData.length == 1, "The verification method didn't return a bool");
        // return returnData[0]==0;
        bool check = verifier_contract.verifyTx(proof_struct.a, proof_struct.b, proof_struct.c, verifier_inputs);
        return check;
    }


    function castProof(bytes memory proof_bytes) internal pure returns (Proof memory){
        require(proof_bytes.length==256, "the proof should be 256 bytes long");
        uint[2] memory a;
        a[0] = bytesToInt(proof_bytes, 0);
        a[1] = bytesToInt(proof_bytes, 32);
        uint[2][2] memory b;
        b[0][0] = bytesToInt(proof_bytes, 64);
        b[1][0] = bytesToInt(proof_bytes, 96);
        b[0][1] = bytesToInt(proof_bytes, 128);
        b[1][1] = bytesToInt(proof_bytes, 160);
        uint[2] memory c;
        c[0] = bytesToInt(proof_bytes, 192);
        c[1] = bytesToInt(proof_bytes, 224);
        return Proof(a,b,c);
    }

    function bytesToInt(bytes memory b, uint offset) private pure returns (uint256) {
        bytes32 out;
        for (uint i = 0; i < 32; i++) {
            out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
        }
        return uint256(out);
    }
}



