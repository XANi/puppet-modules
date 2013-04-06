
class pxe::ipxe {
    package {[
              'ipxe',
              'ipxe-qemu',
              ]:
                  ensure => installed,
    }
    file {'/var/tftp/ipxe.0':
        ensure => link,
        target => '/usr/lib/ipxe/ipxe.pxe',
    }
    file {'/var/tftp/ipxe.qemu.0':
        ensure => link,
        target => '/usr/lib/ipxe/virtio-net.rom',
    }
}
