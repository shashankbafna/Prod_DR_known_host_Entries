#!/bin/bash

# Usage: ./generate_known_hosts_entry.sh <cname1> <cname2> ... <cnamen>

if [ $# -lt 2 ]; then
  echo "Usage: $0 <cname1> <cname2> ... <cnamen>"
  exit 1
fi

# First argument is considered as cnameA
cnameA=$1
shift

# Retrieve the public key from the current host's ~/.ssh directory and encode it in Base64
public_key=$(cat ~/.ssh/id_rsa.pub | base64 -w0)

if [ -z "$public_key" ]; then
  echo "Error: No public key found in ~/.ssh/id_rsa.pub"
  exit 1
fi

declare -A ip_map  # Associative array to store CNAMEs grouped by IP address

# Iterate through remaining arguments which are considered as cnames for host B
for cnameB in "$@"; do
  # Resolve all IP addresses of host B using its CNAME
  ips=$(dig +short $cnameB)

  if [ -z "$ips" ]; then
    echo "Error: Unable to resolve IP addresses for $cnameB"
    continue
  fi

  # Iterate through each IP address associated with this CNAME
  for ip in $ips; do
    # Append the cnameB to the existing entry if the IP already exists in the map
    if [ -n "${ip_map[$ip]}" ]; then
      ip_map[$ip]="${ip_map[$ip]},$cnameB"
    else
      ip_map[$ip]="$cnameA,$cnameB"
    fi
  done
done

# Generate the known_hosts entries based on the grouped IPs
for ip in "${!ip_map[@]}"; do
  entry="${ip_map[$ip]} $public_key"
  echo "$entry"
  # Optionally append each entry to the known_hosts file
  # echo "$entry" >> ~/.ssh/known_hosts
done

# Test case to validate the generated entries
echo "--- Test Case ---"
for ip in "${!ip_map[@]}"; do
  expected_entry="${ip_map[$ip]} $public_key"
  generated_entry=$(echo "${ip_map[$ip]} $public_key")
  
  if [ "$expected_entry" != "$generated_entry" ]; then
    echo "Test failed for IP: $ip"
    exit 1
  else
    echo "Test passed for IP: $ip"
  fi
done

echo "All tests passed!"
