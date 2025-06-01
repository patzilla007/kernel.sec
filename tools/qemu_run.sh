#!/bin/bash

sudo qemu-system-x86_64 \
    -m 2G \
    -smp 2 \
    -kernel /home/patzilla007/Desktop/easylkb/kernel/linux-6.6.92/arch/x86/boot/bzImage \
    -append "console=ttyS0 root=/dev/sda earlyprintk=serial net.ifnames=0" \
    -drive file=/home/patzilla007/Desktop/bullseye.img,format=raw \
    -net user,hostfwd=tcp:127.0.0.1:10021-:22 \
    -net nic,model=e1000 \
    -enable-kvm \
    -nographic \
    -pidfile vm.pid \
    2>&1 | tee vm.log
