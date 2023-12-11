#!/bin/bash

# Initialize variables
IMPLEMENTATION_ADDRESS=""

# Function to display usage
usage() {
    echo "Usage: $0 --implementation-address <trusted forwarder implementation address>"
    exit 1
}

# Process arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --implementation-address) IMPLEMENTATION_ADDRESS=$2; shift ;;
        *) usage ;;
    esac
    shift
done

# Check if all parameters are set
if [ -z "$IMPLEMENTATION_ADDRESS" ]; then
    usage
fi

address=$(cast abi-encode "signature(address)" $IMPLEMENTATION_ADDRESS)
address=${address:2}
echo $address

factoryCode="$(forge inspect src/TrustedForwarderFactory.sol:TrustedForwarderFactory bytecode)"
echo $factoryCode

initCode="$factoryCode$address"
echo $initCode

cast create2 --starts-with 000000 --init-code $initCode