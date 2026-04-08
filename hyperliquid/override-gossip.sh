STATIC_PEERS='["157.90.207.92", "57.129.140.247", "91.134.71.237", "173.231.43.98","136.243.70.112","142.132.131.162","15.235.226.235"]'

curl -s -X POST --header "Content-Type: application/json" --data '{ "type": "gossipRootIps" }' https://api.hyperliquid.xyz/info \
  | jq -c --argjson static "$STATIC_PEERS" \
    '{root_node_ips: (($static | map({"Ip": .})) + [.[] | {"Ip": .}]), try_new_peers: false, chain: "Mainnet", reserved_peer_ips: $static}' \
  > override_gossip_config.json