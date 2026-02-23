# zk-age-proof - Flowcharts

## Main Execution Flow

```
[Start] --> [Write Circuit: ageVerifier.circom]
[Write Circuit: ageVerifier.circom] --> [Compile: circom --r1cs --wasm --sym]
[Compile: circom --r1cs --wasm --sym] --> [Trusted Setup: Powers of Tau]
[Trusted Setup: Powers of Tau] --> [Phase 2 Key Gen: groth16 setup]
[Phase 2 Key Gen: groth16 setup] --> [Generate Witness from input.json]
[Generate Witness from input.json] --> [Generate Proof: groth16 fullprove]
[Generate Proof: groth16 fullprove] --> [Verify Proof: groth16 verify]
[Verify Proof: groth16 verify] --> [End]
```

## Zero-Knowledge Proof Flow

```
PROVER SIDE:
[Private Input: age=25] --> [Circuit: ageVerifier] --> [Generate Witness] --> [Generate ZK Proof]

PUBLIC CHANNEL:
[ZK Proof] ------------------> [Verification Key]
                                    |
                                    V
                              [Verify Proof]

VERIFIER LEARNS ONLY:
[isValid = 1] + [age >= 18] (but NOT age=25)
```

## Circuit Logic

```
         +------------------+
         |   age >= minAge? |
         +------------------+
                |
       +--------+--------+
       |                 |
    [YES]             [NO]
       |                 |
       V                 V
 +------------+    +------------+
 | isValid=1  |    | isValid=0  |
 +------------+    +------------+
       |                 |
       V                 V
 +------------+    +------------+
 |   Proof   |    |    Proof   |
 | Generated |    |    Failed  |
 +------------+    +------------+
```

## Complete ZK Protocol

```
Prover                    Circuit                 Verifier
  |                          |                       |
  |---- Private: age=25 ---->|                       |
  |---- Public: minAge=18 -->|                       |
  |                          |                       |
  |<--- Witness ----------->|                       |
  |                          |                       |
  |---- ZK Proof ---------->|                       |
  |                          |---- proof.json ----->|
  |                          |---- public.json ---->|
  |                          |---- verification_key|
  |                          |                     |
  |                          |    [Verify Math]   |
  |                          |                     |
  |<---- Verified! --------->|                     |
  |                          |                       |
```

## File Generation Flow

```
ageVerifier.circom
       |
       v
  [circom compiler]
       |
       +---> ageVerifier.r1cs
       +---> ageVerifier.wasm  
       +---> ageVerifier.sym

pot12.ptau + ageVerifier.r1cs
       |
       v
 [groth16 setup]
       |
       v
  circuit.zkey
       |
       v
 [zkey contribute]
       |
       v
 circuit_final.zkey --> verification_key.json

ageVerifier.wasm + input.json
       |
       v
 [generate_witness]
       |
       v
   witness.wtns

witness.wtns + circuit_final.zkey
       |
       v
  [fullprove]
       |
       +---> proof.json
       +---> public.json [1, 18]
```

## Verification Flow

```
                    snarkjs groth16 verify
                              |
          +-------------------+-------------------+
          |                   |                   |
    proof.json          public.json       verification_key.json
          |                   |                   |
          +-------------------+-------------------+
                              |
                              v
                     [Verify Math]
                              |
                    +---------+---------+
                    |                   |
                 [Valid]            [Invalid]
                    |                   |
                    V                   V
            +-------------+      +-------------+
            | Proof       |      | Invalid     |
            | Verified!   |      | Proof       |
            +-------------+      +-------------+
```

## Visual Summary

```
┌─────────────────────────────────────────────────────────────────┐
│                    ZK AGE VERIFICATION                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│   ┌─────────┐     ┌──────────────┐     ┌──────────────────┐   │
│   │ PROVER │────▶│   CIRCUIT    │────▶│   VERIFIER       │   │
│   └─────────┘     └──────────────┘     └──────────────────┘   │
│       │                 │                      │                 │
│   age=25          isValid=1              learns only:         │
│   (secret)                            age >= 18 (not age=25)    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
