/*
 * ageVerifier.circom
 * 
 * Zero-Knowledge Proof of Age Verification
 * Proves that a person is over a certain age without revealing the actual age
 * 
 * Author: zk-age-proof
 * License: MIT
 */

include "circomlib/circuits/comparators.circom";

template AgeVerifier() {
    // Private input: actual age of the person
    signal private input age;
    
    // Public input: minimum required age
    signal input minAge;
    
    // Output: 1 if age >= minAge, 0 otherwise
    signal output isValid;

    // Use LessThan to check if age < minAge
    // If age < minAge, then out = 1
    // If age >= minAge, then out = 0
    
    component lt = LessThan(32);
    lt.in[0] <== age;
    lt.in[1] <== minAge;
    
    // isValid = 1 - lt.out
    // If age < minAge (lt.out = 1), isValid = 0
    // If age >= minAge (lt.out = 0), isValid = 1
    isValid <== 1 - lt.out;
}

// Main component
component main = AgeVerifier();
