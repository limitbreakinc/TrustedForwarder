#!/usr/bin/env bash

if [ -f .env.sepolia ]
then
  export $(cat .env.sepolia | xargs) 
else
    echo "Please set your .env.sepolia file"
    exit 1
fi

# Converts human readable gas to wei
./script/common/gwei-to-wei.sh "${GAS_PRICE}"
gasPrice=`cat /tmp/gasfile`
rm -f /tmp/gasfile

# Converts human readable gas to wei
./script/common/gwei-to-wei.sh "${PRIORITY_GAS_PRICE}"
priorityGasPrice=`cat /tmp/gasfile`
rm -f /tmp/gasfile

echo ""
echo "============= DEPLOYING FORWARDER FACTORY ============="

echo "Deployer Key: ${PRIVATE_KEY}"
echo "Deployer Address: ${PUBLIC_KEY}"
echo "RPC: ${RPC_URL}"
echo "Implementation Address: ${IMPLEMENTATION_ADDRESS}"
read -p "Do you want to proceed? (yes/no) " yn

case $yn in 
	yes ) echo ok, we will proceed;;
	no ) echo exiting...;
		exit;;
	* ) echo invalid response;
		exit 1;;
esac

forge create src/TrustedForwarderFactory.sol:TrustedForwarderFactory --rpc-url $RPC_URL \
    --private-key ${PRIVATE_KEY} --build-info --silent \
    --gas-price ${gasPrice} --priority-gas-price ${priorityGasPrice} \
    --constructor-args ${IMPLEMENTATION_ADDRESS}