#!/bin/bash
if [ -f .env.common ]
then
  export $(cat .env.common | xargs) 
else
    echo "Please set your .env.common file"
    exit 1
fi

implementationAddress=$(cast abi-encode "signature(address)" $EXPECTED_TRUSTED_FORWARDER_IMPLEMENTATION_ADDRESS)
implementationAddress=${implementationAddress:2}

echo "create2 TrustedForwarderFactory START"
trustedForwarderFactoryCode="$(forge inspect src/TrustedForwarderFactory.sol:TrustedForwarderFactory bytecode)"
trustedForwarderFactoryInitCode="$trustedForwarderFactoryCode$implementationAddress"
cast create2 --starts-with FF0000 --case-sensitive --init-code $trustedForwarderFactoryInitCode
echo "create2 TrustedForwarderFactory END"
echo "-------------------------------------"
echo ""