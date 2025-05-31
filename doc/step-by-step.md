# Instructions for Building Savanna Network

## Environment

Many linux OS will work, these instructions have been validated on `ubuntu 22.04`.

### Prerequisites
Apt-get and install the following
https://github.com/VaultaFoundation/bootstrap-private-network/blob/main/AntelopeDocker#L3-L20

## Build Antelope Software
You will need to build the following Antelope software from source, using the specified git branches. The software should be built in the following order to satisfy dependancies `Spring`, followed by `CDT`, followed by `Reference Contracts`.

These Git Commit Hashes or Tags are current to the following date.
https://github.com/VaultaFoundation/bootstrap-private-network/blob/eb3a4ee2cf6e27dc6e2f51af64411512bd7e4100/bin/docker-build-image.sh#L5

### Branches
- Spring: branch `release/1.1` repo `AntelopeIO/spring`
- CDT: branch `release/4.1` repo `AntelopeIO/cdt`
- Reference Contracts: branch `main` repo `AntelopeIO/reference-contracts`

[Full Instructions for Building Spring](https://github.com/AntelopeIO/spring?tab=readme-ov-file#build-and-install-from-source), [Full Instructions for Building CDT](https://github.com/antelopeio/cdt?tab=readme-ov-file#building-from-source) or you can review the [Reference Script to Build Spring and CDT](/bin/build_antelope_software.sh).
[Full Instructions for Building System Contracts](https://github.com/VaultaFoundation/system-contracts/?tab=readme-ov-file#building) [Instructions for Building Vaulta Contracts](https://github.com/VaultaFoundation/vaulta-system-contract) or you can review [Scripts Used Here to Build Contracts](/bin/build_contracts.sh).

## Install Antelope Software
Now that the binaries are build you need to add CDT and Spring to your path or install them into well know locations. The [Reference Install Script](/bin/install_antelope_software.sh) must be run as root and demonstrates one way to install the software.

Note, the `System Contracts`, `Vaulta Contracts`, `Time Contract` are install later during the initialization of the EOS blockchain.

## Initialize Block Chain
Before we can start up our multi-producer blockchain a few preparations are needed.
#### `Create New Key Pair`
We will create a new key pair for the root user of the blockchain. You will use the Public Key often in the setup, so please save these keys for use later. You will see a `PublicKey` and `PrivateKey` printed to the console using the following command.
`cleos create key --to-console`
We create three additional key pairs for each of our producers. Here the producers are named `bpa`, `bpb`, `bpc`. In addition on line [#82](https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/finality_test_network.sh#L82) we create the BLS keys needed to finalize votes as part of the Savanna consensus. 
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/finality_test_network.sh#L72-L83
#### `Create Genesis File`
Take the reference [Genesis File](/config/genesis.json) and replace the value for `Initial Key` with the `PublicKey` generated previously. Replace the the value for `Initial Timestamp` with now. In linux you can get the correct format for the date with the following command `date +%FT%T.%3N`.
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/finality_test_network.sh#L87-L89
#### `Shared Config`
We use a shared config file for the common configuration values. Configuration here is only for preview development purposes and should not be used as a reference production config. Copy [config.ini](/config/config.ini) to your filesystem. Additional configuration values will be added on the command line.
#### `Create Log and Data Dir`
You will need to create three data directories, one for each instance of nodeos you will run. You will need a place for log files as well. For example:
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/finality_test_network.sh#L90-L93
#### `Create Wallet`
You need to create and import the root private key into a wallet. This will allow you to run initialization commands on the blockchain. In the example below we have a named wallet and we save the wallet password to a file.
Then import your Root `PrivateKey` adding it to the wallet. We do not need to import our keys for each of the block producers.
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/finality_test_network.sh#L101-L102
If you have already created a wallet you may need to unlock your wallet using your password
https://github.com/VaultaFoundation/bootstrap-private-network/blob/eb3a4ee2cf6e27dc6e2f51af64411512bd7e4100/bin/open_wallet.sh#L19
#### `Initialization Data`
Taking everything we have prepared we will now start a `nodoes` instance. We will be issuing commands while nodes is running so run this command in the background, or be prepared to open multiple terminals on your host. You'll notice we specified the
- genesis file
- config file
- data directory for first instance
- public and private key from our very first step
It is very important to include the option `--enable-stale-production`, we will need that to bootstrap our network.
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/finality_test_network.sh#L151-L161

## Creating Contracts and Accounts
One the node is running we need to run two scripts to add accounts and contracts. We break down this process into three steps.
- boot actions
- create accounts
- block producer setup

#### `Boot Actions`
[boot_actions.sh](/bin/boot_actions.sh) is the reference script. You pass in the following values, reference contracts is your locale git repository where you build the reference contracts software.

- 127.0.0.1:8888
- $DIR/reference-contracts/build/contracts
- PublicKey

This script creates the system accounts.
https://github.com/VaultaFoundation/bootstrap-private-network/blob/eb3a4ee2cf6e27dc6e2f51af64411512bd7e4100/bin/boot_actions.sh#L15-L32

We create 2,100,000,000 EOS tokens. 
https://github.com/VaultaFoundation/bootstrap-private-network/blob/eb3a4ee2cf6e27dc6e2f51af64411512bd7e4100/bin/boot_actions.sh#L34-L36

Below we activate the protocols needed to support Savanna and create the `boot`, and `system` contracts.
https://github.com/VaultaFoundation/bootstrap-private-network/blob/eb3a4ee2cf6e27dc6e2f51af64411512bd7e4100/bin/boot_actions.sh#L40-L50

#### `Create A Token`
We add the A-Token contracts and initialize with an amount equal to the total EOS tokens, 2,100,000,000 A tokens
https://github.com/VaultaFoundation/bootstrap-private-network/blob/eb3a4ee2cf6e27dc6e2f51af64411512bd7e4100/bin/initalize_A_tokens.sh#L26-L42

#### `Create Accounts`

[create_accounts.sh](/bin/create_accounts.sh) takes two arguments
- 127.0.0.1:8888
- $WALLET_DIR

Next we create 3 producer accounts, one for each of our nodes. After creating the keys, we create the accounts, allocate EOS, and add some resources.
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/create_accounts.sh#L19-L23

We create 26 users accounts. These accounts will stake resources and vote for producers. Same commands we used to create the producers. The only difference is funding amounts.
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/create_accounts.sh#L39-L43

#### `Block Producer Setup`
[block_producer_setup](/bin/block_producer_setup.sh) is the reference script. You pass in the following values

- 127.0.0.1:8888
- $WALLET_DIR

This script create registers new block producers and users vote for producers.
https://github.com/VaultaFoundation/bootstrap-private-network/blob/eb3a4ee2cf6e27dc6e2f51af64411512bd7e4100/bin/block_producer_setup.sh#L15-L16
https://github.com/VaultaFoundation/bootstrap-private-network/blob/eb3a4ee2cf6e27dc6e2f51af64411512bd7e4100/bin/block_producer_setup.sh#L30

#### `Root User Control`
We give our three block producers explicit rights to invoke `eosio` root privileges via multi-sig.  
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/set_authorities.sh#L18-L51

#### `Experimental Features`
Here we add the `null.vaulta` account and create an official `noop` action [noop_contract.sh](/bin/noop_contract.sh). These are features we are trying out and may be moved into production. 

## Create Network
Now that we have initialized a node with everything we need, we will create a network of three nodes. The Second and Third nodes will start from genesis and pull updates from the First node. The First nodes has already been initialized and it will start from its existing state. Soon each node will have the same information and the same head block number.

In the examples below we user different `PublicKey` and `PrivateKey` for each producer.

#### `Node One`
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/finality_test_network.sh#L151-L161
#### `Node Two`
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/finality_test_network.sh#L176-L186
#### `Node Three`
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/finality_test_network.sh#L212-L222

## Activate Savanna
For the last step we will activate the new Savanna algorithm.

#### `Register Finalizer Key`
Earlier we created our BLS finalizer keys. In each node startup script the BLS finalizer keys are provided as arguments. Now we register the keys. We need to register three finalizer keys, one for each of our nodes. 
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/register_bls_finalizer_key.sh#L22-L24

#### `Activate Savanna`
The final step is to activate savanna. This is done with a action that takes no arguments. The permission required is `eosio@active`
https://github.com/VaultaFoundation/bootstrap-private-network/blob/f4d7dd209bd121d035c6b2d5fef9b841d49421d2/bin/finality_test_network.sh#L261

#### `Verify Faster Finality`
Here you can check the Head Block Number and Last Irreversible Block and see they are three apart. `cleos get info`

In addition you can check your logs for the following strings, the will provide information on the exact block where the transition will/does occur.
- `Transitioning to savanna`
- `Transition to instant finality`

Congratulations you are running a Private Vaulta network with the new, faster finality, Savanna algorithm.
