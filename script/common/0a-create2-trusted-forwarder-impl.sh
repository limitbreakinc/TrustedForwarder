#!/bin/bash
cast create2 --starts-with FF0000 --case-sensitive --init-code $(forge inspect src/TrustedForwarder.sol:TrustedForwarder bytecode)