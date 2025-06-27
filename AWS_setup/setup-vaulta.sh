#!/bin/bash

#########################
# run this to setup on a host not a docker container
#########################

# Become enfuser for repo actions
sudo -u enfuser bash <<'EOF'

# Setup working directories
mkdir -p /local/VaultaFoundation/repos
cd /local/VaultaFoundation/repos

# Clone repositories
git clone -b sync_call https://github.com/AntelopeIO/spring.git
git clone -b call_abi https://github.com/AntelopeIO/cdt.git
git clone https://github.com/AntelopeIO/reference-contracts.git
git clone https://github.com/VaultaFoundation/system-contracts.git
git clone -b dev-testnet https://github.com/VaultaFoundation/bootstrap-private-network.git
git clone https://github.com/VaultaFoundation/eosio.time
git clone https://github.com/VaultaFoundation/vaulta-system-contract.git

# Build Antelope software
cd /local/VaultaFoundation/repos/bootstrap-private-network
/local/VaultaFoundation/repos/bootstrap-private-network/bin/build_antelope_software.sh

EOF

# Install Antelope software (as root)
bash /local/VaultaFoundation/repos/bootstrap-private-network/bin/install_antelope_software.sh

# Build contracts (as enfuser)
sudo -u enfuser bash <<'EOF'
/local/VaultaFoundation/repos/bootstrap-private-network/bin/build_contracts.sh
EOF

# Preserve built packages
mkdir -p /local/VaultaFoundation/software/spring
mkdir -p /local/VaultaFoundation/software/cdt

mv /local/VaultaFoundation/spring_build/antelope-spring_*.deb /local/VaultaFoundation/software/spring
mv /local/VaultaFoundation/repos/cdt/build/tools/bin /local/VaultaFoundation/software/cdt

echo "✅ Vaulta environment setup complete."
