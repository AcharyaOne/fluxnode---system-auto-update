#!/bin/bash

# Get the current timestamp
timestamp=$(date +"%Y-%m-%d %T")

# Get the node information
node=$(/usr/local/bin/flux-cli getinfo)

# Check if flux-cli command is successful
if [ $? -ne 0 ]; then
    echo "$timestamp Error: flux-cli command failed"
    exit 1
fi

# Extract the status from the node information
status=$(echo $node | jq '.status' -r)

# Extract the version from the node information
ver=$(echo $node | jq '.version' -r)

# Check if the version exists
if [ -z $ver ]; then
    # If version does not exist, exit the script
    echo "$timestamp Error: version not found"
    exit 1
else
    # Get the blockchain information
    blockchain=$(curl https://api.runonflux.io/daemon/getblockcount)

    # Check if curl command is successful
    if [ $? -ne 0 ]; then
        echo "$timestamp Error: curl command failed"
        exit 1
    fi 

    # Extract the current height from the blockchain information
    current_height=$(echo $blockchain | jq '.data' -r)

    # Extract the confirmed height from the node information
    confirmed_height=$(echo $node | jq '.last_confirmed_height' -r)

    # Calculate the number of blocks in maintenance
    maintanance_blocks=$(($current_height - $confirmed_height))

    # Calculate the number of blocks until maintenance
    maintanace=$((120 - $maintanance_blocks))

    # Update the package list
    sudo apt-get update -qq -y

    echo "$timestamp Updated"

    # Check for updates
    updates=$(apt list --upgradable 2>/dev/null | wc -l)

    # If no updates are available
    if [ $updates -eq 1 ]; then
        # Print a message and exit the script
        echo "$timestamp No updates available."
        exit 0
    else
        # Upgrade the packages
        sudo apt-get upgrade -qq -y

        echo "$timestamp Upgraded"

        # Print a message
        echo "$timestamp Updates installed, checking if reboot is required"

        # Check if a reboot is required
        if systemctl list-jobs --no-legend --full --all | grep 'reboot.target' ; then
          # Check if node CONFIRMED
          if [ $status != "CONFIRMED" ]; then
            echo "$timestamp Reboot..."
            sudo reboot
          else
            if [ $maintanace -le 20 ]; then
              delay=$(((maintanace*2)+80))
              #Schedule reboot after delay
              echo "$timestamp Scheduling reboot after $delay minutes"
              sudo shutdown -r +$delay
            else
              echo "$timestamp Reboot..."
              sudo reboot
            fi
          fi
        else
      	   #If reboot is not required, exit the script
      	   echo "$timestamp No reboot required"
      	   exit 0
      	 fi
       fi
      fi

