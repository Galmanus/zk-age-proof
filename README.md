# zk-age-proof 🔐🎂

> **Zero-Knowledge Age Verification** - Prove you are over 18 without revealing your actual age!

![ZKP](https://img.shields.io/badge/Zero%20Knowledge-Proofs-blue)
![Circom](https://img.shields.io/badge/Circom-orange)
![snarkjs](https://img.shields.io/badge/snarkjs-yellow)
![License](https://img.shields.io/badge/License-MIT-green)

## 📋 Project Description

**zk-age-proof** is a demonstration project for **Zero-Knowledge Proofs (ZKP)** for age verification. It allows someone to prove they are over 18 (or any minimum age) without revealing their actual age.

### How it works?

1. **Private Input**: The person's actual age (e.g., 25 years old)
2. **Public Input**: The minimum required age (e.g., 18 years old)
3. **Output**: A cryptographic proof that verifies `age >= minAge` without revealing `age`

## 🛠️ Technologies Used

| Technology | Description |
|------------|-------------|
| **Circom** | Domain-specific language for arithmetic circuits |
| **snarkjs** | JavaScript library for SNARK proofs |
| **Groth16** | ZK proof scheme used |
| **BN128** | Elliptic curve for cryptographic pairings |

## 📦 Installation

### Prerequisites

- **Node.js** (v14 or higher)
- **npm** (v6 or higher)

### Step 1: Install Node.js

```bash
# Using nvm (recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18

# Or download directly from https://nodejs.org/
```

### Step 2: Install ZK Tools

```bash
# Install circom globally
npm install -g circom

# Install snarkjs globally
npm install -g snarkjs

# Verify installation
circom --version
snarkjs --version
```

### Step 3: Clone and Setup the Project

```bash
# Clone or download this project
cd zk-age-proof

# Install project dependencies (if any)
npm install
```

## 🚀 How to Run

### Running the Automatic Script

The easiest way is to use the automated script:

```bash
cd zk-age-proof
chmod +x scripts/run.sh
./scripts/run.sh
```

### Running Manually (Step by Step)

If you prefer to do it manually, follow these steps:

#### 1. Compile the Circuit

```bash
cd circuits
circom ageVerifier.circom --r1cs --wasm --sym --c
cd ..
```

#### 2. Trusted Setup (Powers of Tau)

```bash
# Create new powers of tau (12 bits for quick testing)
snarkjs powersoftau new bn128 12 keys/pot12_0000.ptau -v

# Contribute (in production, this would be a ceremony with multiple participants)
echo "test" | snarkjs powersoftau contribute keys/pot12_0000.ptau keys/pot12_0001.ptau --name="first contribution" -v
```

#### 3. Phase 2 Setup (Generate Keys)

```bash
# Generate zkey
snarkjs groth16 setup circuits/ageVerifier.r1cs keys/pot12_0001.ptau keys/circuit_0000.zkey

# Contribute to phase 2
echo "test" | snarkjs zkey contribute keys/circuit_0000.zkey keys/circuit_0001.zkey --name="contribution" -v

# Export verification key
snarkjs zkey export verificationkey keys/circuit_0001.zkey keys/verification_key.json
```

#### 4. Generate the Proof

```bash
# Modify inputs/input.json with your age
# Example: {"age": 25, "minAge": 18}

# Generate witness
node circuits/ageVerifier_js/generate_witness.js \
    circuits/ageVerifier_js/ageVerifier.wasm \
    inputs/input.json \
    keys/witness.wtns

# Generate proof
snarkjs groth16 fullprove \
    inputs/input.json \
    circuits/ageVerifier_js/ageVerifier.wasm \
    keys/circuit_0001.zkey \
    keys/proof.json \
    keys/public.json
```

#### 5. Verify the Proof

```bash
snarkjs groth16 verify keys/verification_key.json keys/public.json keys/proof.json
```

If everything goes well, you'll see:

```
[✓] ✓ Proof verified
```

## 📊 Expected Result

### Input (in `inputs/input.json`):
```json
{
  "age": 25,
  "minAge": 18
}
```

### Output:
- ✅ Proof verified successfully
- The Verifier only knows that `age >= 18`, but doesn't know the exact age (25)

### Testing with Invalid Age:

Change the input to:
```json
{
  "age": 16,
  "minAge": 18
}
```

The proof will fail, proving the system works correctly!

## 📁 Project Structure

```
zk-age-proof/
├── circuits/
│   ├── ageVerifier.circom      # Main circuit
│   ├── ageVerifier.r1cs       # Compiled
│   ├── ageVerifier.sym        # Symbols
│   └── ageVerifier_js/        # Generated JS code
│       └── ageVerifier.wasm
├── scripts/
│   └── run.sh                  # Automated script
├── inputs/
│   └── input.json              # Input example
├── keys/
│   ├── pot12_0001.ptau         # Powers of Tau
│   ├── circuit_0001.zkey      # Verification key
│   ├── verification_key.json   # Exported VK
│   ├── proof.json             # Generated proof
│   └── public.json            # Public inputs
├── README.md
├── LICENSE
├── package.json
└── .gitignore
```

## ⚠️ Security Notes

> **IMPORTANT**: This project is for **learning and testing only**!

- The included Trusted Setup is **for demonstration purposes only**
- In production, you should do a **complete trusted setup ceremony** (like the Perpetual Powers of Tau Trusted Setup)
- Never use test keys in real applications
- For production, consider using **Groth16 with an open ceremony** or **PLONK/KZG** with universal setup

### Best Practices for Production:

1. **Trusted Setup**: Organize a ceremony with multiple participants
2. **Audit**: Have the circuit audited by experts
3. **Circuit Hash**: Publish the circuit hash for transparency
4. **On-chain Verification**: Consider verifying the proof in a smart contract

## 🔧 Troubleshooting

### Error: "circom not found"
```bash
export PATH="$PATH:$(npm root -g)/bin"
# Or restart your terminal
```

### Error: "snarkjs command not found"
```bash
npm install -g snarkjs
```

### Compilation Error
Make sure you're in the correct directory:
```bash
cd zk-age-proof
ls circuits/
```

## 📝 License

This project is licensed under the **MIT License**. See the [LICENSE](LICENSE) file for details.

---

Made with ❤️ using Zero-Knowledge Proofs

## 📚 References

- [Circom Documentation](https://docs.circom.io/)
- [snarkjs Documentation](https://github.com/iden3/snarkjs)
- [Zero-Knowledge Proofs](https://en.wikipedia.org/wiki/Zero-knowledge_proof)
- [Circomlib](https://github.com/iden3/circomlib)

