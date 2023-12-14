#!/usr/bin/env bash

if [ -f .env.secrets ]
then
  export $(cat .env.secrets | xargs) 
else
    echo "Please set your .env.secrets file"
    exit 1
fi

if [ -f .env.common ]
then
  export $(cat .env.common | xargs) 
else
    echo "Please set your .env.common file"
    exit 1
fi

# Initialize variables
CHAIN_ID=""
ETHERSCAN_API_KEY=""

# Function to display usage
usage() {
    echo "Usage: $0 --chain-id <chain id>"
    exit 1
}

# Function to set verification api key based on chain ID
set_etherscan_api_key() {
  case $1 in
      1) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_ETHEREUM ;;
      10) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_OPTIMISM ;;
      56) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_BSC ;;
      137) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_POLYGON ;;
      324) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_ETHEREUM ;;
      1101) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_POLYGON_ZKEVM ;;
      8453) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_BASE ;;
      42161) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_ARBITRUM ;;
      42170) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_ARBITRUM_NOVA ;;
      43114) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_ETHEREUM;; #Avalanche C-Chain
      59144) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_LINEA ;;
      7777777) echo "Unsupported chain id"; exit 1 ;; #Zora
      534352) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_SCROLL ;;
      5) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_ETHEREUM ;;
      999) echo "Unsupported chain id"; exit 1 ;; #Zora Testnet
      5001) echo "Unsupported chain id"; exit 1 ;; #Mantle Testnet
      59140) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_LINEA ;;
      80001) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_POLYGON ;; 
      84531) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_BASE ;;
      534353) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_SCROLL ;; # Scroll Alpha
      11155111) ETHERSCAN_API_KEY=$VERIFICATION_API_KEY_ETHEREUM ;;
      2863311531) echo "Unsupported chain id"; exit 1 ;; # Ancient 8 Testnet
      13472) echo "Unsupported chain id"; exit 1 ;; # Immutable X Testnet
      *) echo "Unsupported chain id"; exit 1 ;;
  esac

  export ETHERSCAN_API_KEY
}

# Process arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --gas-price) GAS_PRICE=$(($2 * 1000000000)); shift ;;
        --priority-gas-price) PRIORITY_GAS_PRICE=$(($2 * 1000000000)); shift ;;
        --chain-id) CHAIN_ID=$2; shift ;;
        *) usage ;;
    esac
    shift
done

# Check if all parameters are set
if [ -z "$CHAIN_ID" ]; then
    usage
fi

# Set the ETHERSCAN API KEY based on chain ID
set_etherscan_api_key $CHAIN_ID

echo ""
echo "============= VERIFYING CONTRACTS ============="

echo "Chain ID: $CHAIN_ID"
echo "EXPECTED_TRUSTED_FORWARDER_IMPLEMENTATION_ADDRESS: $EXPECTED_TRUSTED_FORWARDER_IMPLEMENTATION_ADDRESS"
echo "EXPECTED_TRUSTED_FORWARDER_FACTORY_ADDRESS: $EXPECTED_TRUSTED_FORWARDER_FACTORY_ADDRESS"
read -p "Do you want to proceed? (yes/no) " yn

case $yn in 
  yes ) echo ok, we will proceed;;
  no ) echo exiting...;
    exit;;
  * ) echo invalid response;
    exit 1;;
esac

forge verify-contract --watch --optimizer-runs 1000000 --chain-id $CHAIN_ID $EXPECTED_TRUSTED_FORWARDER_IMPLEMENTATION_ADDRESS src/TrustedForwarder.sol:TrustedForwarder
forge verify-contract --watch --optimizer-runs 1000000 --chain-id $CHAIN_ID --constructor-args $(cast abi-encode "constructor(address)" $EXPECTED_TRUSTED_FORWARDER_IMPLEMENTATION_ADDRESS) $EXPECTED_TRUSTED_FORWARDER_FACTORY_ADDRESS src/TrustedForwarderFactory.sol:TrustedForwarderFactory