#!/bin/bash
# elevate if necessary
if [[ $EUID -ne 0 ]]; then
    exec sudo "$0" "$@"
fi

kmsg() {
    echo "libvirt-hook: $@" >/dev/kmsg
}

VM=$1

# if the VM name does not start with 'workstation-', exit
[[ $VM =~ ^workstation- ]] || exit 0

kmsg "executing for vm $VM, state $2"

# todo: fix this to be more dynamic
ALL_CPUS=0-43
HOST_CPUS=0-9,22-31
GUEST_CPUS=10-21,32-43

UNDOFILE=/var/run/libvirt/qemu/vfio-isolate-undo.$VM.bin

disable_isolation () {
	vfio-isolate \
		restore $UNDOFILE

	taskset -pc $ALL_CPUS 2  # kthreadd reset
	kmsg "disabled isolation"
}

enable_isolation () {
	vfio-isolate \
		-u $UNDOFILE \
		drop-caches \
		cpu-governor performance \
		cpuset-modify --cpus C$HOST_CPUS /system.slice \
		cpuset-modify --cpus C$HOST_CPUS /user.slice \
		compact-memory \
		irq-affinity mask C$GUEST_CPUS

	taskset -pc $HOST_CPUS 2  # kthreadd only on host cores
	kmsg "enabled isolation"
}

case "$2" in
"prepare")
	enable_isolation
	;;
"started")
	;;
"release")
	disable_isolation
	;;
esac
