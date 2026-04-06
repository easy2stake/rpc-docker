STATIC_PEERS='["173.231.43.98","136.243.70.112"]'

curl -s -X POST --header "Content-Type: application/json" --data '{ "type": "gossipRootIps" }' https://api.hyperliquid.xyz/info \
  | jq -c --argjson static "$STATIC_PEERS" \
    '{root_node_ips: ([.[] | {"Ip": .}] + ($static | map({"Ip": .}))), try_new_peers: false, chain: "Mainnet", reserved_peer_ips: $static}' \
  > override_gossip_config.json