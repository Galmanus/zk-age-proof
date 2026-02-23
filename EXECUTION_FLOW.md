# zk-age-proof - Execution Flow Explanation

## Overview

This project demonstrates Zero-Knowledge Proofs (ZKP) for age verification using Circom and snarkjs. The flow allows someone to prove they are over 18 without revealing their actual age.

## Execution Flow

### 1. Circuit Design (ageVerifier.circom)

The circuit receives:
- Input: age (PRIVATE) - e.g., 25
- Input: minAge (PUBLIC) - e.g., 18
- Output: isValid - 1 if age >= minAge

The circuit uses LessThan from circomlib:
- isValid = 1 - LessThan(age, minAge)
- If age < minAge → LessThan returns 1 → isValid = 0
- If age >= minAge → LessThan returns 0 → isValid = 1

### 2. Compilation

Command: circom ageVerifier.circom --r1cs --wasm --sym --c

Outputs:
- ageVerifier.r1cs - Binary constraints in R1CS format
- ageVerifier.wasm - WebAssembly for witness generation
- ageVerifier.sym - Symbol table for debugging

### 3. Trusted Setup (Powers of Tau)

Commands:
- snarkjs powersoftau new bn128 12 pot12_0000.ptau
- echo "contribution" | snarkjs powersoftau contribute pot12_0000.ptau pot12_0001.ptau

Purpose: Generate toxic waste (toxic tau) that must be discarded. This creates the initial trusted setup.

### 4. Phase 2 - Key Generation

Commands:
- snarkjs groth16 setup ageVerifier.r1cs pot12_0001.ptau circuit_0000.zkey
- echo "contribution" | snarkjs zkey contribute circuit_0000.zkey circuit_final.zkey
- snarkjs zkey export verificationkey circuit_final.zkey verification_key.json

Outputs:
- circuit_final.zkey - Proving key (kept secret by prover)
- verification_key.json - Verification key (public)

### 5. Witness Generation

Command:
node circuits/ageVerifier_js/generate_witness.js circuits/ageVerifier_js/ageVerifier.wasm inputs/input.json keys/witness.wtns

Input: {"age": 25, "minAge": 18}

Output: witness.wtns - Computed signals satisfying the circuit

### 6. Proof Generation

Command:
snarkjs groth16 fullprove inputs/input.json circuits/ageVerifier_js/ageVerifier.wasm keys/circuit_final.zkey keys/proof.json keys/public.json

What happens:
1. Prover uses their private input (age=25)
2. Circuit computes: isValid = 1 (because 25 >= 18)
3. Generates cryptographic proof that this computation is correct
4. Only public output is revealed: [1, 18]

Public output: [isValid, minAge] = [1, 18]
- The verifier knows only that isValid = 1 and minAge = 18
- The verifier does NOT know the actual age (25)

### 7. Proof Verification

Command:
snarkjs groth16 verify verification_key.json public.json proof.json

What the verifier checks:
1. The proof was generated from the correct circuit
2. The public inputs satisfy the circuit constraints
3. The proof is mathematically valid

Result: [OK] Verification successful

## Security Properties

- Zero-Knowledge: Verifier learns nothing about age, only that age >= 18
- Soundness: Cannot fake a proof if age < minAge
- Completeness: Valid proofs always verify

## Running the Project

cd zk-age-proof
chmod +x scripts/run.sh
./scripts/run.sh

This executes the entire flow automatically.

## Testing Different Ages

Valid age (25): {"age": 25, "minAge": 18}
Output: isValid = 1 Proof verified

Invalid age (16): {"age": 16, "minAge": 18}
Output: isValid = 0 Proof fails

This proves the system works correctly!
