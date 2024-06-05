for host in 192.168.0.129 192.168.0.131 192.168.0.134; do
    ssh-keyscan -H $host >> ~/.ssh/known_hosts
done
