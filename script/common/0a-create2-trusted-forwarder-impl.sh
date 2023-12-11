#!/bin/bash
echo $(forge inspect src/TrustedForwarder.sol:TrustedForwarder bytecode)
cast create2 --starts-with 000000 --init-code $(forge inspect src/TrustedForwarder.sol:TrustedForwarder bytecode)