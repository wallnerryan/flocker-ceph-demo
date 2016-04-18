#!/usr/bin/env bash

set -eu

########################
# include the magic
########################
. demo-magic.sh

TYPE_SPEED=15
DEMO_PROMPT="${GREEN}➜ ${BLUE}\W${BROWN}$ "

# hide the evidence
clear

# ************************************************************
# Run the demo:
# ************************************************************

wait
p " # Install the needed tools"
p "brew install flocker-1.11.0"
p "brew install ansible"
p "vagrant plugin install vai"

wait
p " # Clone the needed repositories"
pe "git clone https://github.com/ClusterHQ/flocker-ceph-vagrant"
pe "cd flocker-ceph-vagrant"

wait
pe "git clone https://github.com/ceph/ceph-ansible.git"
pe "cd ceph-ansible"

wait
p " # Prepare the environment by copying needed configuration files"
pe "./../ready_env.sh"

wait
pe "vagrant up --provider=virtualbox"

wait
pe "head -n 18  ansible/inventory/vagrant_ansible_inventory"

wait
p " # Let's look at the status of our cluster"
p "vagrant ssh ceph2 -c 'sudo ceph -s'"
vagrant ssh ceph2 -c "sudo ceph -s"

wait
p "vagrant ssh ceph1 -c 'sudo curl --cacert /etc/flocker/cluster.crt \
   --cert /etc/flocker/plugin.crt \
   --key /etc/flocker/plugin.key \
   --header Content-type: application/json \
   https://ceph1:4523/v1/state/nodes | python -m json.tool'"

vagrant ssh ceph1 -c "sudo curl --cacert /etc/flocker/cluster.crt \
   --cert /etc/flocker/plugin.crt \
   --key /etc/flocker/plugin.key \
   --header Content-type: application/json \
   https://ceph1:4523/v1/state/nodes | python -m json.tool"

wait
p " # Let's create a Docker volume that provisions a Ceph volume via the Flocker driver"
p "vagrant ssh ceph3 -c 'sudo docker volume create -d flocker --name test -o size=10G'"
vagrant ssh ceph3 -c "sudo docker volume create -d flocker --name test -o size=10G"
p " # wait about 10 seconds before listing the mountpoints for the volume to attach"

wait
p "vagrant ssh ceph3 -c 'sudo df -h | grep flocker'"
vagrant ssh ceph3 -c "sudo df -h | grep flocker"

wait
p " # Now let's run a container that uses that volume" 
p "vagrant ssh ceph3 -c 'sudo docker run --volume-driver flocker \
   -v test:/data --name test-container -itd busybox'"
vagrant ssh ceph3 -c "sudo docker run --volume-driver flocker \
   -v test:/data --name test-container -itd busybox"

wait
p " # Now let's view our container running"
p "vagrant ssh ceph3 -c 'sudo docker ps'"
vagrant ssh ceph3 -c "sudo docker ps"

wait
p " # View the mountpoint inside the container"
p "vagrant ssh ceph3 -c 'sudo docker inspect -f {{.Mounts}} test-container'"
vagrant ssh ceph3 -c "sudo docker inspect -f "{{.Mounts}}" test-container"

wait
p " # View the dataset state in Flocker metadata service"
p "vagrant ssh ceph1 -c 'sudo curl --cacert /etc/flocker/cluster.crt \
   --cert /etc/flocker/plugin.crt \
   --key /etc/flocker/plugin.key \
   --header Content-type: application/json \
   https://ceph1:4523/v1/state/datasets | python -m json.tool'"
vagrant ssh ceph1 -c "sudo curl --cacert /etc/flocker/cluster.crt \
   --cert /etc/flocker/plugin.crt \
   --key /etc/flocker/plugin.key \
   --header 'Content-type: application/json' \
   https://ceph1:4523/v1/state/datasets | python -m json.tool"

wait
p " # Remove the container and start a new container on `ceph4` to demonstrate the volume moves with the container"
p "vagrant ssh ceph3 -c 'sudo docker rm -f test-container'"
vagrant ssh ceph3 -c "sudo docker rm -f test-container"
p "vagrant ssh ceph4 -c 'sudo docker run --volume-driver flocker \
   -v test:/data --name test-container -itd busybox'"
vagrant ssh ceph4 -c "sudo docker run --volume-driver flocker \
   -v test:/data --name test-container -itd busybox"

wait
p " # our volume and container are no longer on `ceph3`"
p "vagrant ssh ceph3 -c 'sudo docker ps'"
p "vagrant ssh ceph3 -c 'sudo df -h | grep flocker'"

wait
p " # We can see it is not present on `ceph4`
p "vagrant ssh ceph4 -c 'sudo docker ps'"
vagrant ssh ceph4 -c "sudo docker ps"

wait
p "vagrant ssh ceph4 -c 'sudo df -h | grep flocker'"
vagrant ssh ceph4 -c "sudo df -h | grep flocker"

wait
p " # That's it! Now we can clean up the environment"
pe "vagrant destroy -f"


