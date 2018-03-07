#
# Efifs UEFI docker
#
# Docker file to start a Ubuntu docker instance on machines utilizing sshd with public key
# authentication for specified users and keys with tools necessary for building UEFI Efifs
# based projects; all items needed for OVMF are ready
#
# Build it like so:
#   root@host~# docker build -t=geneerik/docker-edk2-uefi-efifs $(pwd)
#
# Generate ssh keys; in this example we will only use the current user
# and expect the private key to be called id_rsa and the public key to be call
# id_rsa.pub.  Both files are expected to reside in the users /home/username/.ssh
# directory.  If you need to generate an ssh key; google is your friend (hint: github instructions)
#
# Launch the generated image like so (note: this allows the container to connect
# to your system's systemd service; caviet emptor):
#
#   docker run -d -p 2222:22 -v /home/$(whoami)/.ssh/id_rsa.pub:/home/$(whoami)/.ssh/authorized_keys -e SSH_USERS="$(whoami):$(id -u $(whoami)):$(id -g $(whoami))" --name geneerik-tianocore-sshd-efifs geneerik/docker-edk2-uefi-efifs
#
# Now that the instance is started, run the following command to add the user to
# the container
#
#   root@host~# docker exec -e SSH_USERS="$(whoami):$(id -u $(whoami)):$(id -g $(whoami))" geneerik-tianocore-sshd-efifs /sbin/createsshuser.sh
#
# Many users can be defined at once, however all users created this way will automatically get
# sudo access, so be mindful
#
# Connect like so, with the password requested shown when the exec command above is executed.
#
#   $ ssh -X -o "UserKnownHostsFile=/dev/null" -o "StrictHostKeyChecking=no" $(docker inspect -f "{{ .NetworkSettings.Networks.bridge.IPAddress }}" geneerik-tianocore-sshd-efifs)
#
# Please note: in order to utilize the OVMF images with qemu, you will need to forward X11 (the flag is included
# in the command above, but X11 forwarding can be complex depending on your host system)
#
# Gene Erik
# --

#
#  From this base-image / starting-point

FROM geneerik/docker-edk2-uefi:latest

ENV EFIFS_BRANCH ${EFIFS_BRANCH:-master}
ENV EFIFS_ARCH ${EFIFS_ARCH:-IA32}

#
#  Authorship
#
MAINTAINER geneerik@thisdomaindoesntexistyet.com

#Install prerequisites for building tianocore
RUN DEBIAN_FRONTEND=noninteractive apt-get update && DEBIAN_FRONTEND=noninteractive apt-get upgrade  --yes --force-yes
#install prerequisites for sshd
RUN DEBIAN_FRONTEND=noninteractive apt-get install less sudo openssh-server openssh-client --yes --force-yes

#Create script to clone the Tianocore repo and set the branch to EDK_BRANCH
RUN ( bash -c 'echo -e "#!/bin/bash\n\n" > /usr/local/bin/getefifs.sh' ) && ( echo 'mkdir -p /opt/src/ && \
	cd /opt/src && \
	git clone git clone https://github.com/pbatard/efifs && \
	cd efifs && \
	( for branch in `git branch -a | grep remotes | grep -v HEAD | grep -v master `; do git branch --track ${branch#remotes/origin/} $branch; done ) && \
	git pull --tags && \
	git checkout ${EFIFS_BRANCH} && \
	git pull --all && \
	git submodule init && \
	git submodule update && \
	cd ../edk2 && \
	ln -s ../efifs EfiFsPkg' >> /usr/local/bin/getefifs.sh ) && \
	chmod +x /usr/local/bin/getefifs.sh
	
#create script to build efifs
RUN ( echo '#!/bin/bash' >> /usr/local/bin/buildmde.sh ) && \
	( echo 'cd /opt/src/efifs && ./set_grub_cpu.sh ${EFIFS_ARCH} && cd ../edk2 && ( build -a ${EFIFS_ARCH} -p EfiFsPkg/EfiFsPkg.dsc 2>&1 | tee build_efifs.log )' >> /usr/local/bin/buildmde.sh ) && \
	chmod +x /usr/local/bin/buildmde.sh
