#!/usr/bin/env bash
####################################################################################################
# 20250501 - Written by Nic Fragale @ NetFoundry.
MyName="HostEnum.sh"
MyPurpose="Enumerates to hosts file DNS records in the form of an IP."
MyWarranty="This program comes without any warranty, implied or otherwise."
MyLicense="This program has no license."
MyVersion="1.20250501"
####################################################################################################

# Enumerate all IP addresses in a given CIDR network.
# Usage: ./myname.sh "10.20.10.0/28" "domain.tld"

if [ "$#" -lt 2 ] || [[ "${3}" == "-h" ]]; then
  echo "Usage: $0 \"<network>/<cidr>\" \"<domain>\" \"WRITE or DELETE or NOWRITE\""
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

# Split the network into IP and cidr parts.
IFS='/' read -r ip cidr <<< "${network}"

# Validate cidr (should be between 0 and 32)
if ! [[ "${cidr}" =~ ^[0-9]+$ ]] || [ "${cidr}" -lt 0 ] || [ "${cidr}" -gt 32 ]; then
  echo "Invalid cidr: ${cidr}"
  exit 1
fi

# Split the IP address into its four octets.
IFS='.' read -r o1 o2 o3 o4 <<< "${ip}"

# Convert the IP address to a single 32-bit integer.
ip_int=$(( (o1 << 24) + (o2 << 16) + (o3 << 8) + o4 ))

# Get the mask of the network.
mask=$(( 0xFFFFFFFF << (32 - cidr) & 0xFFFFFFFF ))

# Get the base of the network.
base_int=$(( ip_int & mask ))

# Split the base IP address into its four octets.
o1=$(( (base_int >> 24) & 0xFF )) \
o2=$(( (base_int >> 16) & 0xFF )) \
o3=$(( (base_int >> 8) & 0xFF )) \
o4=$(( base_int & 0xFF ))

# Calculate the total number of IP addresses in the range.
num_addresses=$(( 1 << (32 - cidr) ))

# Loop through and convert each integer back to dotted-quad format.
for (( i=0; i<num_addresses; i++ )); do
    current=$(( base_int + i ))
    a=$(( (current >> 24) & 0xFF ))
    b=$(( (current >> 16) & 0xFF ))
    c=$(( (current >> 8) & 0xFF ))
    d=$(( current & 0xFF ))
    fulladdress[0]="${a}.${b}.${c}.${d}"
    fulladdress[1]="${a}.${b}.${c}.${d}.${domain}"
    fulladdress[2]="${i}.${domain}"
    if [[ "${outmode}" == "WRITE" ]]; then
        if ! grep "${fulladdress[1]}" "${outfile}" &>/dev/null; then
            echo "<${outmode}> ${fulladdress[*]}"
            echo "${fulladdress[*]}" >> "${outfile}"
        else
            echo "<SKIP> ${fulladdress[*]}"
        fi
    elif [[ "${outmode}" == "DELETE" ]]; then
        if grep "${fulladdress[1]}" "${outfile}" &>/dev/null; then
            echo "<${outmode}> ${fulladdress[*]}"
            gsed -i '/'"${fulladdress[1]}"'/ d' "${outfile}" &>/dev/null
        else
            echo "<SKIP> ${fulladdress[*]}"
        fi
    elif [[ "${outmode}" == "NOWRITE" ]]; then
        echo "${fulladdress[*]}"
    fi
done
