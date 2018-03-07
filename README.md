# UEFI EDKII Development Environment

This docker container can be used to build projects based on the Tiano EDKII UEFI project.

It is possible to selected the branch of the EDKII project to be used and compiled at container creation as well as the target architecture.  Build Tools are compiled on first ssh login triggered in bashrc.  qemu can be run with X over ssh.  Scripts are included to build MdeModulePkg and OVMF.  Script included to create base for OVMF qemu environment and start qemu (script only for x86/64 right now).

Please note that the OVMF that is build is OvmfPkg/OvmfPkgIa32X64.dsc .  For other options, see https://github.com/tianocore/tianocore.github.io/wiki/How-to-build-OVMF for the required modifications.

## Instructions to Run

The following is the most basic way to run.  Assuming the host system is 64 bit and the targets desired are ia32 and x64.

0) Ensure you have public and private keys for ssh set up for your user; this example expects the files for the identity to be id_rsa.pub and id_rsa. https://www.howtoforge.com/linux-basics-how-to-install-ssh-keys-on-the-shell
1) Build or pull this image.  If building: docker build -t=geneerik/docker-edk2-uefi $(pwd)
2) Create the container; the "-e MAX_CONCURRENT_THREAD_NUMBER=..." part can be omitted if this information cannot be retrieved for some reason or the host system is not unix-like or in an external docker host (like aws, VirtualBox, or on exeternal kubernetes): docker run -d -p 2222:22 -v /home/$(whoami)/.ssh/id_rsa.pub:/home/$(whoami)/.ssh/authorized_keys -e SSH_USERS="$(whoami):$(id -u $(whoami)):$(id -g $(whoami))" -e MAX_CONCURRENT_THREAD_NUMBER=$(($(nproc) + 1)) --name geneerik-tianocore-builder geneerik/tianocore-sshd
3) Create the user in the container and set a temporary password; the user will be forced to change this on first login; take note of the temporary password as it will be needed. Command: docker exec -e SSH_USERS="$(whoami):$(id -u $(whoami)):$(id -g $(whoami))" geneerik-tianocore-builder /sbin/createsshuser.sh
4) Login to the container with ssh and change the password; you will be logged out as soon as the password is changed.  this assumes the container is exposed via local host; if usingkubernetes or some other non-standard docker setup, this command will be different.  Command: ssh -P2222 localhost
5) Once the password is changed log in again via ssh; this will trigger cloning of source repo and building of build tools.  This will only happen on the first log in of ANY user.  Command: ssh -P2222 localhost
6) Once build is complete, you will be presented with a bash shell.  Kick off building of MdeModules and OVMF then start the qemu to verify with the following command: buildmdeandovmf3264.sh && startqemux8664ovmf.sh

Thats it.  Now you can continue with the rest of your needs for the edk2 packages.  Enjoy!

Note: It may be desired to use a different branch or tag of the tianocore source files.  To do so, add to the paramater (without quotes) "-e EDK_BRANCH=UDK2017" or some other branch or tag, with this example using the UDK2017 branch.  To switch architecture, the TARGET_ARCH environmental variable can be used in the container run command like "-e TARGET_ARCH=IA32", though the "buildmdeandovmf3264.sh && startqemux8664ovmf.sh" example will not work for non-default values.  Caveat emptor.  If bulding for a non-x84/64 based system you would need to do quite a few things as building for ARM (AARCH) is way more complicated.  Some hints: https://wiki.linaro.org/LEG/UEFIforQEMU
