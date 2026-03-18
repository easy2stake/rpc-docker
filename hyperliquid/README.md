# Running a node

## Machine Specs

| Role          | vCPUs | RAM    | Storage    |
| ------------- | ----- | ------ | ---------- |
| Non-Validator | 16    | 64 GB  | 500 GB SSD |

Currently only Ubuntu 24.04 is supported.

Ports 4001 and 4002 are used for gossip and must be open to the public. Otherwise, the node IP address will be deprioritized by peers in the p2p network.

For lowest latency, run the node in Tokyo, Japan.

---

## Setup

### Configure Chain

The Docker image is configured for **Mainnet** in the [Dockerfile](Dockerfile).

### override_gossip_config.json

Non-validators on Mainnet need at least one seed peer IP to bootstrap. The node uses `~/override_gossip_config.json` to discover initial peers. This repo includes a static config in [override_gossip_config.json](override_gossip_config.json). To update it with fresh IPs from the API (requires `jq`):

```bash
cd hyperliquid
echo "{ \"root_node_ips\": $(curl -s -X POST --header "Content-Type: application/json" --data '{ "type": "gossipRootIps" }' https://api.hyperliquid.xyz/info | jq '[.[] | {"Ip": .}]'), \"try_new_peers\": false, \"chain\": \"Mainnet\", \"reserved_peer_ips\": [] }" > override_gossip_config.json
docker compose build node && docker compose up -d
```

## Running

Copy [env.template](env.template) to `.env` and edit if needed, then start:

```bash
cp env.template .env
docker compose up -d
```

It may take a while as the node navigates the network to find an appropriate peer to stream from. Logs such as `applied block X` indicate that the node is streaming live data. View logs with `docker compose logs -f`.

---

## Reading L1 Data

The node writes data to the mounted volume (default `$HOME/hl-data` on host, `~/hl/data` in container). With default settings, the network will generate around 100 GB of logs per day, so it is recommended to archive or delete old files. The pruner service handles this automatically.

For more information about examples and all the data types that can be written, see [Reading L1 Data](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/nodes/reading-l1-data).

- **Transaction Blocks:**
  Blocks parsed as transactions are streamed to:

  ```
  replica_cmds/{start_time}/{date}/{height}
  ```

- **State Snapshots:**
  State snapshots are saved every 10,000 blocks to:

  ```
  periodic_abci_states/{date}/{height}.rmp
  ```

  To translate the state to JSON or compute L4 snapshots, run `hl-node` inside the container:

  ```bash
  docker compose exec node hl-node --chain Mainnet translate-abci-state /home/hluser/hl/data/periodic_abci_states/{date}/{height}.rmp /tmp/out.json
  docker compose exec node hl-node --chain Mainnet compute-l4-snapshots <abci-state-path> <out-path>
  ```

---

## Flags

The node is started with `--serve-eth-rpc` and `--serve-info` (see [docker-compose.yml](docker-compose.yml)). Additional flags can be added to the `command` section. The data schemas for the output data are documented in [L1 Data Schemas](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/nodes/l1-data-schemas).

- `--write-trades`: Streams trades to `node_trades/hourly/{date}/{hour}`.
- `--write-fills`: Streams fills in the API fills format. Also streams TWAP statuses. This overrides `--write-trades` if both are set.
- `--write-order-statuses`: Writes every L1 order status. Note that orders can be a substantial amount of data.
- `--write-raw-book-diffs`: Writes every L1 order diff. Note that raw book diffs can be a substantial amount of data.
- `--write-hip3-oracle-updates`: Writes every HIP-3 deployer oracle update action.
- `--write-misc-events`: Writes miscellaneous event data. See [Miscellaneous Events](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/nodes/reading-l1-data#miscellaneous-events) for more details.
- `--write-system-and-core-writer-actions`: Writes CoreWriter and HyperCore to HyperEVM transfer data.
- `--batch-by-block`: Writes the above files with one block per line instead of one event per line. The batched data schema is `{local_time, block_time, block_number, events}`, where `events` is a list.
- `--stream-with-block-info`: Writes events as they are processed instead of once per block, but uses the same data schema as `--batch-by-block` to include block metadata.
- `--replica-cmds-style`: Configures what is written to `replica_cmds/{start_time}/{date}/{height}`.
  Options:
  - `actions` (default) – only actions
  - `actions-and-responses` – both actions and responses
  - `recent-actions` – only preserves the two latest height files
- `--disable-output-file-buffering`: Flush each line immediately when writing output files. This reduces latency but leads to more disk IO operations.
- `--serve-eth-rpc`: Enables the EVM RPC (see next section).
- `--serve-info`: Enables local HTTP server to handle info requests (see next section).

Add flags to the `command` in [docker-compose.yml](docker-compose.yml) as needed.

---

## EVM and Info servers

The node runs with `--serve-eth-rpc` and `--serve-info` by default. RPC is available at `http://localhost:3001` (or `${RPC_PORT}` from [env.template](env.template)). For example, to retrieve the latest block:

```bash
curl -X POST --header 'Content-Type: application/json' --data '{"jsonrpc":"2.0","method":"eth_getBlockByNumber","params":["latest",false],"id":1}' http://localhost:3001/evm
```

The info server at `http://localhost:3001/info` handles info requests with the API request/response format. See [Info Endpoint](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint) for more details. Running a local info server can help with rate limits and reduces trust assumptions on external operators. Currently the local server only supports a subset of requests that are entirely a function of local state. In particular, historical time series queries and websockets are not currently supported. The `--write-*` flags on the node can be used for historical and streaming purposes.

The currently supported info requests on the local server are

```
    meta
    spotMeta
    clearinghouseState
    spotClearinghouseState
    openOrders
    exchangeStatus
    frontendOpenOrders
    liquidatable
    activeAssetData
    maxMarketOrderNtls
    vaultSummaries
    userVaultEquities
    leadingVaults
    extraAgents
    subAccounts
    userFees
    userRateLimit
    spotDeployState
    perpDeployAuctionStatus
    delegations
    delegatorSummary
    maxBuilderFee
    userToMultiSigSigners
    userRole
    perpsAtOpenInterestCap
    validatorL1Votes
    marginTable
    perpDexs
    webData2 (does not compute assetCtxs, which do not depend on the user)
```

The info server also supports requests that writes down large local snapshot data to a file. This can be a better way to get snapshot data if an info server is running, because it uses the latest state instead of an older snapshot file.

The info request format is:

```
    {"type": "fileSnapshot", "request": <SnapshotRequest>, "outPath": <string>, "includeHeightInOutput": <bool>}
```

`<SnapshotRequest>` format is:

```
    {"type": "referrerStates"}
    {"type": "l4Snapshots", "includeUsers": <bool>, "includeTriggerOrders": <bool>}
```

Some info requests such as `l2Book` are not currently supported, as they are only indexed by a small number of assets and can be easily polled or subscribed to within the standard rate limits.

To ensure that the server information is up to date, `exchangeStatus` can be pinged periodically to compare L1 and local timestamps. The server information can be ignored when the L1 timestamp returned is sufficiently stale.

---

## Delegation

To delegate tokens to a validator, run `hl-node` inside the container:

```bash
docker compose exec node hl-node --chain Mainnet --key <delegator-wallet-key> staking-deposit <wei>
docker compose exec node hl-node --chain Mainnet --key <delegator-wallet-key> delegate <validator-address> <amount-in-wei>
docker compose exec node hl-node --chain Mainnet --key <delegator-wallet-key> staking-withdrawal <wei>
```

View delegations via the [Mainnet API](https://api.hyperliquid.xyz/info) with `{"type": "delegations", "user": <delegator-address>}`.

---

## Troubleshooting

Crash logs from the child process are written to `visor_child_stderr/{date}/{node_binary_index}` in the data volume.

---

## References

| Link | Purpose |
|------|---------|
| [Reading L1 Data](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/nodes/reading-l1-data) | Data types, paths, examples |
| [L1 Data Schemas](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/nodes/l1-data-schemas) | Schemas for `--write-*` output |
| [Miscellaneous Events](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/nodes/reading-l1-data#miscellaneous-events) | `--write-misc-events` format |
| [Info Endpoint](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/info-endpoint) | Local info server API |
| [Mainnet API](https://api.hyperliquid.xyz/info) | gossipRootIps, delegations, etc. |
| [Testnet API](https://api.hyperliquid-testnet.xyz/info) | Testnet info requests |
| [Mainnet hl-visor](https://binaries.hyperliquid.xyz/Mainnet/hl-visor) | Mainnet binary |
| [Testnet hl-visor](https://binaries.hyperliquid-testnet.xyz/Testnet/hl-visor) | Testnet binary |
