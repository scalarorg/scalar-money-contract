# Foundry Template

A template for Foundry projects.

## Overview

This project is a template for Foundry projects.

## Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Bun](https://bun.sh/) (or Node.js)

## Installation

1. Clone the repository:

```sh
git clone https://github.com/0xdavid7/foundry-template.git
cd foundry-template
```

2. Install dependencies:

```sh
bun install
```

## Environment Setup

Create a `.env` file in the root directory with the following variables:

```sh
ALCHEMY_API_KEY=
API_KEY_ETHERSCAN=
PRIVATE_KEY=
```

## Testing

Run all tests:

```sh
make test-all
```

Run specific test:

```sh
make test <test-file>
```

## How to deploy

1. Default deployment:

```sh
make deploy
```
