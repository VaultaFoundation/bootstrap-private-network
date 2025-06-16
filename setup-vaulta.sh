#!/bin/bash
set -e

# Create directories
mkdir -p /local/VaultaFoundation
mkdir -p /bigata1/log
mkdir -p /bigata1/savanna/nodeos-one
mkdir -p /bigata1/savanna/nodeos-two
mkdir -p /bigata1/savanna/nodeos-three

# Set permissions
chmod 777 /local/VaultaFoundation
chmod 777 /bigata1/log
chmod 777 /bigata1/savanna
chmod 777 /bigata1/savanna/nodeos-one
chmod 777 /bigata1/savanna/nodeos-two
chmod 777 /bigata1/savanna/nodeos-three

echo 'root:${1:-Docker!}' | chpasswd

# Create user enfuser if not exists
if ! id -u enfuser >/dev/null 2>&1; then
    useradd -ms /bin/bash enfuser
fi

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

mv /local/VaultaFoundation/spring_build/antelope-spring_*.deb /local/VaultaFoundation/software/spring || true
mv /local/VaultaFoundation/repos/cdt/build/tools/bin /local/VaultaFoundation/software/cdt || true

# Clean up unnecessary files
rm -rf /local/VaultaFoundation/repos/spring/.git/modules || true
find /local/VaultaFoundation/repos/spring/ -name "build" -type d | xargs rm -rf || true
rm -rf /local/VaultaFoundation/repos/cdt/build || true
rm -rf /local/VaultaFoundation/spring_build/ || true
rm -rf /local/VaultaFoundation/repos/cdt || true
rm -rf /local/VaultaFoundation/repos/spring || true

echo "✅ Vaulta environment setup complete."
