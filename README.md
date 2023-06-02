# FairWheel (Work In Progress)
A non-custodial NFT marketplace that uses a gamified auction mechanism to sell NFTs to buyers.

> ## Table of contents
- [Overview](#overview)
- [Project Features](#project-features)
- [Technologies](#technologies)
- [Repo Setup](#repo-setup)
- [Setup with Foundry](#setup-with-foundry)
- [Setup the Frontend](#setup-the-frontend)
  - [Install Dependencies](#install-dependencies)
  - [Start Server](#start-server)
  - [Build the Frontend](#build-the-frontend)
- [FairWheel Contract Address](#fairwheel-contract-address)
- [Live Link](#live-link)
- [Contributions](#contributions)
- [Thank You](#thank-you)
- [TODO](#todo)
#

## Overview
<p align="justify">
A non-custodial NFT marketplace that uses a gamified auction mechanism to sell NFTs to buyers. The logic is based on the aggregation of the value of NFT's present in each pools to develop a floor price where every auction bid starts from.  
</p>

<p align="justify">
We are building a digital asset marketplace that is fair to everyone. Buyers can buy NFTs without the fear of it depreciating due to no demand. FairWheel's pools will highly influence demand and supply.
</p>

<p align="justify">
 
</p>

#
> ## Project Features

- Gamified auction mechanism where buyers have fair chances of bidding on a claim to a Nft from a pool of multiples.

- Semi-custodial logic of sellers digital assets and profits.

- Auctions are MEV resistant.

- 10 pools of closely-priced assets with the top pool holding the expensive assets. 

- Closely-priced assets are available in each pool with an aggregated floor price to start bid from.


</p>

#
> ## Technologies
| <b><u>Stack</u></b> | <b><u>Usage</u></b> |
| :------------------ | :------------------ |
| **`Solidity`**      | Smart contract      |
| **`React JS`**      | Frontend            |
| **`Next JS`**       | Frontend            |
| **`Foundry`**       | Environment         |

#

## Repo Setup

<p align="justify">
The repo has two branches, we'll always push to the "dev" branch first and whenever the commits are reviewed and confirmed, it'll be merged to main.  so ensure to input:
</p>

  $ git checkout - b "dev" 

<p align="justify">
Before adding commits and pushing to the repo.
</p>
  e.g:  
  $ git push upstream dev
#

*Note: This repo uses Foundry, the original repo was cloned from https://github.com/smartcontractkit/foundry-starter-kit*

## Setup with Foundry

<br/>
<p align="center">
<a href="https://chain.link" target="_blank">
<img src="./img/chainlink-foundry.png" width="225" alt="Chainlink Foundry logo">
</a>
</p>
<br/>

[![Open in Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/mainstreetlab/FairWheel)

Foundry Starter Kit is a repo that shows developers how to quickly build, test, and deploy smart contracts with one of the fastest frameworks out there, [foundry](https://github.com/gakonst/foundry)!


- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Quickstart](#quickstart)
  - [Testing](#testing)
- [Deploying to a network](#deploying-to-a-network)
  - [Setup](#setup)
  - [Deploying](#deploying)
    - [Working with a local network](#working-with-a-local-network)
    - [Working with other chains](#working-with-other-chains)
- [Security](#security)
- [Resources](#resources)

### Getting Started

#
> #### Requirements

Please install the following:

-   [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)  
    -   You'll know you've done it right if you can run `git --version`
-   [Foundry / Foundryup](https://github.com/gakonst/foundry)
    -   This will install `forge`, `cast`, and `anvil`
    -   You can test you've installed them right by running `forge --version` and get an output like: `forge 0.2.0 (f016135 2022-07-04T00:15:02.930499Z)`
    -   To get the latest of each, just run `foundryup`

And you probably already have `make` installed... but if not [try looking here.](https://askubuntu.com/questions/161104/how-do-i-install-make)

#
#### Quickstart

```sh
git clone https://github.com/mainstreetlab/FairWheel
cd FairWheel
make # This installs the project's dependencies.
make test
```

#
> #### Testing

```
make test
```

or

```
forge test
```

### Deploying to a network

Deploying to a network uses the [foundry scripting system](https://book.getfoundry.sh/tutorials/solidity-scripting.html), where you write your deploy scripts in solidity!

#
> #### Setup

Here's a demo using the Goerli testnet. (Go here for [testnet goerli ETH](https://faucets.chain.link/).)

You'll need to add the following variables to a `.env` file:

-   `GOERLI_RPC_URL`: A URL to connect to the blockchain. You can get one for free from [Alchemy](https://www.alchemy.com/). 
-   `POLYGON_RPC_URL`:The URL to connect to the polygon blockchain. You can get it on [Alchemy](https://www.alchemy.com/). 
-   `PRIVATE_KEY`: A private key from your wallet. You can get a private key from a new [Metamask](https://metamask.io/) account
    -   Additionally, if you want to deploy to a testnet, you'll need test ETH and/or LINK. You can get them from [faucets.chain.link](https://faucets.chain.link/).
-   `ETHERSCAN_API_KEY`: If you want to verify on etherscan

`To retrieve your etherscan key.`
- Login to [etherscan](https://etherscan.io/) and hover over the dropdown arrow for your profile on the navbar.
- Click on API keys and add to create a new project (optional step).
- Once the project has been created, click on the copy button to copy the API key.
- Paste it in the .env file

<p align="center" width="100%">
  <img src="https://drive.google.com/uc?export=view&id=1Gq-hPuwjwb3TOCH2dqUA93VxfyrbUDN6" alt="etherscan key"/>
</p>

#
> #### Deploying

```
make deploy-goerli contract=<CONTRACT_NAME>
```

For example:

```
make deploy-goerli contract=PriceFeedConsumer
```

This will run the forge script, the script it's running is:

```
@forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${GOERLI_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast --verify --etherscan-api-key ${ETHERSCAN_API_KEY}  -vvvv
```

If you don't have an `ETHERSCAN_API_KEY`, you can also just run:

```
@forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${GOERLI_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast 
```

These pull from the files in the `script` folder. 

#
> ##### Working with a local network

Foundry comes with local network [anvil](https://book.getfoundry.sh/anvil/index.html) baked in, and allows us to deploy to our local network for quick testing locally. 

To start a local network run:

```
make anvil
```

This will spin up a local blockchain with a determined private key, so you can use the same private key each time. 

Then, you can deploy to it with:

```
make deploy-anvil contract=<CONTRACT_NAME>
```

Similar to `deploy-goerli`

#
> ##### Working with other chains

To add a chain, you'd just need to make a new entry in the `Makefile`, and replace `<YOUR_CHAIN>` with whatever your chain's information is. 

```
deploy-<YOUR_CHAIN> :; @forge script script/${contract}.s.sol:Deploy${contract} --rpc-url ${<YOUR_CHAIN>_RPC_URL}  --private-key ${PRIVATE_KEY} --broadcast -vvvv

```


### Security

The framework comes with slither parameters, a popular security framework from [Trail of Bits](https://www.trailofbits.com/). To use slither, you'll first need to [install python](https://www.python.org/downloads/) and [install slither](https://github.com/crytic/slither#how-to-install).

Then, you can run:

```
make slither
```

And get your slither output. 


### Resources

-   [Chainlink Documentation](https://docs.chain.link/)
-   [Foundry Documentation](https://book.getfoundry.sh/)


#

## Setup the Frontend
- First run the frontend on your local server to ensure it's fully functional before building for production.
#
> ### Install Dependencies
- Setup and install dependencies

```shell
$ cd frontend

$ npm install

$ npm install react-scripts@latest    -or use next.js
```
#
> ### Start Server
- Start the server on localhost
```
$ npm run start
```
#
> ### Build the Frontend
- Create an optimized production build, which can be hosted on sites like Heroku, Netlify, Surge etc.
```
$ npm run build
```
#

## Contributions

Contributions are always welcome! Open a PR or an issue!


#

## Thank You!


 ## TODO

[ ] A token wrapper NFT - ERC1155 to hold funds sent by buyer

[ ] A registry contract for available tokens that can be used to pay purchase fees

[ ] A fully functional frontend that can be interacted with
#
> ## FairWheel Contract Address

- ****

#  
> ## Live Link
  
- ******
#




> ###### README Created by `MAINSTREET LAB` for FairWheel