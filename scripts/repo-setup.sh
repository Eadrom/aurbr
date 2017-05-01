#!/usr/bin/env bash

set -e

if [ ! -e "$HOME/.config/aurbr/vps_api_token" ]; then
    echo "Could not find ~/.config/aurbr/vps_api_token"
    mkdir -vp ~/.config/aurbr
    touch ~/.config/aurbr/vps_api_token
    chmod 0600 ~/.config/aurbr/vps_api_token
    echo '#!/usr/bin/env bash' > ~/.config/aurbr/vps_api_token
    echo 'API_TOKEN="TOKEN_GOES_HERE"' >> ~/.config/aurbr/vps_api_token
    echo "Created file."
    echo "Please add your token to ~/.config/aurbr/vps_api_token"
    exit 1
fi

source "$HOME"/.config/aurbr/vps_api_token

if [ "$API_TOKEN" == "" ] || [ "$API_TOKEN" == "TOKEN_GOES_HERE" ] ; then
    echo "Could not find API token in ~/.config/aurbr/do_token"
    exit 1
fi

# Need to move API_TOKEN to unified settings file
# Need to add config option to be able to specify fingerprint of SSH key to use
# Need to add a logging location, probably ~/.local/share/aurbr/logs/
# Need to define desired block storage volume size to attach
BLOCK_VOL_SIZE="10"

# Need to define an SSH function that can pass in command to execute remotely
function ssh_do () {
    ssh -q -o StrictHostKeyChecking=no root@"$DROPLET_IP" 'bash -c '"$1"''
}

ACCOUNT_INFO=$(curl -s -X GET -H "Content-Type: application/json" \
               -H "Authorization: Bearer $API_TOKEN" \
               "https://api.digitalocean.com/v2/account")

ACCOUNT_STATUS=$(echo $ACCOUNT_INFO | grep "active")

if [ "$ACCOUNT_STATUS" == "" ]; then
    echo "Unable to determine if account is active."
    echo "Check API token and/or VPS account status."
    exit 1
fi

echo "API token loaded and VPS account is active."

echo "Creating new droplet..."
CREATE_DROPLET_RETURN=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $API_TOKEN" -d '{"name":"repo.aurbr.org","region":"nyc1","size":"512mb","image":"ubuntu-16-04-x64","ssh_keys":["e3:26:f9:72:ab:b9:82:5c:48:a1:c5:b3:46:e1:d6:a9"],"backups":false,"ipv6":true,"user_data":null,"private_networking":null,"volumes": null,"tags":["aurbr"]}' "https://api.digitalocean.com/v2/droplets")
# Might implement a loop here to check for SSH server response instead of waiting arbitrary 50 seconds
echo "...API call succeeded.  Waiting for droplet to spin up..."
sleep 10
echo "...40 seconds left..."
sleep 10
echo "...30 seconds left..."
sleep 10
echo "...20 seconds left..."
sleep 10
echo "...10 seconds left..."
sleep 10
echo "...complete."

DROPLET_ID=$(echo $CREATE_DROPLET_RETURN | cut -d"{" -f3 | cut -d":" -f2 | cut -d"," -f1)
DROPLET_IP=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $API_TOKEN" "https://api.digitalocean.com/v2/droplets/$DROPLET_ID" | cut -d"{" -f7 | cut -d"," -f1 | cut -d"\"" -f4)

echo "Creating DNS record..."
curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $API_TOKEN" -d '{"name":"aurbr.org","ip_address":"'"$DROPLET_IP"'"}' "https://api.digitalocean.com/v2/domains"
curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $API_TOKEN" -d '{"type":"A","name":"repo","data":"'"$DROPLET_IP"'","priority":null,"port":null,"weight":null}' "https://api.digitalocean.com/v2/domains/aurbr.org/records"
echo -e "\n...complete."

echo "Creating block storage volume for package storage..."
BLOCK_VOL_ID=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $API_TOKEN" -d '{"size_gigabytes":'"$BLOCK_VOL_SIZE"', "name": "aurbor-pkg-vault", "description": "Storage volume for AURBR packages", "region": "nyc1"}' "https://api.digitalocean.com/v2/volumes" | cut -d"{" -f3 | cut -d"\"" -f4)
echo "...complete."

echo "Attaching block storage volume to droplet..."
curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $API_TOKEN" -d '{"type": "attach", "droplet_id": '"$DROPLET_ID"', "region": "nyc1"}' "https://api.digitalocean.com/v2/volumes/$BLOCK_VOL_ID/actions"
echo -e "\n...complete."

echo "Beginning host provisioning..."
echo "Droplet connection to Internet is:"
ping -c 5 "$DROPLET_IP" > /dev/null && echo "up" || echo "down"
echo "Testing SSH connection by asking droplet for its hostname:"
ssh_do "hostname"

# Provisioning steps
# Install software:  nginx, sudo, git
# Clone AURBR repository into /opt to make configs and scripts available locally
# Kick off local provisioning script in /opt/aurbr/:
    # Run repo provisioning script:
    # Create admin user (config option in ~/.config/aurbr/settings.conf)
    # Setup new user with temp password, sudo rights, skel files, etc
    # Lock down SSH daemon
    # Install Let's Encrypt
    # Copy over and activate Let's Encrypt nginx config
    # Initialize Let's Encrypt and secure a certificate
    # Create repository directory structures
    # Copy over repository Let's Encrypt config
    # Swap over active config from Let's Encrypt to repository config
    # Restart nginx so it switches over to repo config and starts using TLS
    # Copy over, enable, and start systemd timer to periodically refresh Let's Encrypt cert
    # Create build master user
    # Copy over build configs (active package list, api key, etc)
    # Copy over, enable, and start systemd timer to once a day scan for package updates and build them

echo "...host provisioning complete."
