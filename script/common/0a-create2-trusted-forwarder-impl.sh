#!/bin/bash
cast create2 --starts-with 6ABE00 --init-code $(forge inspect src/TrustedForwarder.sol:TrustedForwarder bytecode)