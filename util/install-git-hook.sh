#!/bin/bash
mkdir -p .git/hooks
cp util/ensure-secrets-encrypted.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
