#!/bin/bash
# Enumerate all IP addresses in a given CIDR network.
# Usage: ./myname.sh "10.20.10.0/28" "domain.tld"

if [ "$#" -lt 2 ] || [[ "${3}" == "-h" ]]; then
  echo "Usage: $0 \"<network>/<prefix>\" \"<domain>\" \"WRITE or DELETE or NOWRITE\""
  exit 1
fi

outfile="/etc/hosts"
network="$1"
domain="$2"
outmode="${3:-NOWRITE}"

# Check outmode.
case "${outmode}" in
    "WRITE"|"DELETE")
        if [[ -f "${outfile}" ]]; then
            echo "### Will \"${outmode}\" in hosts file \"${outfile}\" ###"
        else
            echo "### ERROR: Hosts file \"${outfile}\" does not exist ###"
            exit 1
        fi
    ;;
    "NOWRITE")
        echo "### Will output to screen only ###"
    ;;
    *)
        echo "### ERROR: The mode specified \"${outmode}\" is not valid ###"
        exit 1
    ;;
esac

echo

# Split the network into IP and prefix parts.
IFS='/' read -r ip prefix <<< "$network"

# Validate prefix (should be between 0 and 32)
if ! [[ "$prefix" =~ ^[0-9]+$ ]] || [ "$prefix" -lt 0 ] || [ "$prefix" -gt 32 ]; then
  echo "Invalid prefix: $prefix"
  exit 1
fi

# Split the IP address into its four octets.
IFS='.' read -r o1 o2 o3 o4 <<< "$ip"

# Convert the IP address to a single 32-bit integer.
ip_int=$(( (o1 << 24) + (o2 << 16) + (o3 << 8) + o4 ))

# Calculate the total number of IP addresses in the range.
num_addresses=$(( 1 << (32 - prefix) ))

# Loop through and convert each integer back to dotted-quad format.
for (( i=0; i<num_addresses; i++ )); do
    current=$(( ip_int + i ))
    a=$(( (current >> 24) & 0xFF ))
    b=$(( (current >> 16) & 0xFF ))
    c=$(( (current >> 8) & 0xFF ))
    d=$(( current & 0xFF ))
    fulladdress="$a.$b.$c.$d $a.$b.$c.$d.$domain"
    if [[ "${outmode}" == "WRITE" ]]; then
        if ! grep "${fulladdress}" "${outfile}" &>/dev/null; then
            echo "<${outmode}> ${fulladdress}"
            echo "${fulladdress}" >> "${outfile}"
        else
            echo "<SKIP> ${fulladdress}"
        fi
    elif [[ "${outmode}" == "DELETE" ]]; then
        if grep "${fulladdress}" "${outfile}" &>/dev/null; then
            echo "<${outmode}> ${fulladdress}"
            gsed -i '/'"${fulladdress}"'/ d' "${outfile}" &>/dev/null
        else
            echo "<SKIP> ${fulladdress}"
        fi
    elif [[ "${outmode}" == "NOWRITE" ]]; then
        echo "${fulladdress}"
    fi
done