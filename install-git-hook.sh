#!/bin/bash
mkdir -p .git/hooks
cp ensure-vault-encrypted.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
