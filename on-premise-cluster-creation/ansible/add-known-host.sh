for host in 192.168.56.11 192.168.56.12 192.168.56.13; do
    ssh-keyscan -H $host >> ~/.ssh/known_hosts
done
