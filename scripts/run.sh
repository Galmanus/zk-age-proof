#!/bin/bash

# =============================================================================
# zk-age-proof - Compilation and Proof Generation Script
# =============================================================================
# This script automates the entire process:
# 1. Compile the Circom circuit
# 2. Trusted Setup (Powers of Tau)
# 3. Generate keys (phase 2 setup)
# 4. Generate the proof
# 5. Verify the proof
# =============================================================================

set -e  # Stop on error

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Directories
CIRCUIT_DIR="circuits"
SCRIPT_DIR="scripts"
INPUT_DIR="inputs"
KEYS_DIR="keys"

# Files
CIRCUIT_NAME="ageVerifier"
INPUT_FILE="$INPUT_DIR/input.json"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  zk-age-proof${NC}"
echo -e "${BLUE}  Zero-Knowledge Age Verification${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# -----------------------------------------------------------------------------
# Step 1: Check dependencies
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[1/6] Checking dependencies...${NC}"

if ! command -v circom &> /dev/null; then
    echo -e "${RED}Error: circom is not installed${NC}"
    echo "Install with: npm install -g circom"
    exit 1
fi

if ! command -v snarkjs &> /dev/null; then
    echo -e "${RED}Error: snarkjs is not installed${NC}"
    echo "Install with: npm install -g snarkjs"
    exit 1
fi

echo -e "${GREEN}✓ All dependencies are installed${NC}"
echo ""

# -----------------------------------------------------------------------------
# Step 2: Compile the circuit
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[2/6] Compiling the circuit...${NC}"

cd "$CIRCUIT_DIR"
circom "$CIRCUIT_NAME.circom" --r1cs --wasm --sym --c
cd ..

echo -e "${GREEN}✓ Circuit compiled successfully!${NC}"
echo "   Generated files:"
echo "   - $CIRCUIT_DIR/${CIRCUIT_NAME}.r1cs"
echo "   - $CIRCUIT_DIR/${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm"
echo "   - $CIRCUIT_DIR/${CIRCUIT_NAME}.sym"
echo ""

# -----------------------------------------------------------------------------
# Step 3: Groth16 Setup (Powers of Tau)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[3/6] Running Trusted Setup (Powers of Tau)...${NC}"

# Check if powers of tau already exists
if [ ! -f "$KEYS_DIR/pot12_0000.ptau" ]; then
    echo "Downloading powers of tau (pot12)..."
    # Using an existing powers of tau file for testing
    # For production, do your own ceremony
    snarkjs powersoftau new bn128 12 "$KEYS_DIR/pot12_0000.ptau" -v

    echo "Contributing to the setup..."
    echo "test" | snarkjs powersoftau contribute "$KEYS_DIR/pot12_0000.ptau" "$KEYS_DIR/pot12_0001.ptau" --name="first contribution" -v

    echo "Preparing powers of tau..."
    snarkjs powersoftau prepare phase2 "$KEYS_DIR/pot12_0001.ptau" "$KEYS_DIR/pot12_final.ptau" -v
else
    echo "Using existing powers of tau..."
    if [ -f "$KEYS_DIR/pot12_final.ptau" ]; then
        cp "$KEYS_DIR/pot12_final.ptau" "$KEYS_DIR/pot12_0001.ptau"
    else
        cp "$KEYS_DIR/pot12_0000.ptau" "$KEYS_DIR/pot12_0001.ptau"
    fi
fi

echo -e "${GREEN}✓ Powers of Tau completed!${NC}"
echo ""

# -----------------------------------------------------------------------------
# Step 4: Phase 2 Setup (Key Generation)
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[4/6] Generating verification keys (Phase 2)...${NC}"

snarkjs groth16 setup "$CIRCUIT_DIR/${CIRCUIT_NAME}.r1cs" "$KEYS_DIR/pot12_final.ptau" "$KEYS_DIR/circuit_0000.zkey"

echo "Contributing to phase 2..."
echo "test" | snarkjs zkey contribute "$KEYS_DIR/circuit_0000.zkey" "$KEYS_DIR/circuit_0001.zkey" --name="contribution" -v

# Export verification key
snarkjs zkey export verificationkey "$KEYS_DIR/circuit_0001.zkey" "$KEYS_DIR/verification_key.json"

echo -e "${GREEN}✓ Keys generated successfully!${NC}"
echo "   Generated files:"
echo "   - $KEYS_DIR/circuit_0001.zkey"
echo "   - $KEYS_DIR/verification_key.json"
echo ""

# -----------------------------------------------------------------------------
# Step 5: Generate the proof
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[5/6] Generating Zero-Knowledge proof...${NC}"

# Generate witness using snarkjs
snarkjs wtns calculate "$CIRCUIT_DIR/${CIRCUIT_NAME}.wasm" "$INPUT_FILE" "$KEYS_DIR/witness.wtns"

# Generate proof
snarkjs groth16 prove \
    "$KEYS_DIR/circuit_0001.zkey" \
    "$KEYS_DIR/witness.wtns" \
    "$KEYS_DIR/proof.json" \
    "$KEYS_DIR/public.json"

echo -e "${GREEN}✓ Proof generated successfully!${NC}"
echo "   Generated files:"
echo "   - $KEYS_DIR/proof.json"
echo "   - $KEYS_DIR/public.json"
echo ""

# -----------------------------------------------------------------------------
# Step 6: Verify the proof
# -----------------------------------------------------------------------------
echo -e "${YELLOW}[6/6] Verifying the proof...${NC}"

snarkjs groth16 verify \
    "$KEYS_DIR/verification_key.json" \
    "$KEYS_DIR/public.json" \
    "$KEYS_DIR/proof.json"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Process completed successfully!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "Output files:"
echo "  - Proof: $KEYS_DIR/proof.json"
echo "  - Public inputs: $KEYS_DIR/public.json"
echo ""
echo "To verify manually:"
echo "  snarkjs groth16 verify keys/verification_key.json keys/public.json keys/proof.json"

