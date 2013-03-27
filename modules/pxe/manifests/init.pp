
class pxe::ipxe {
    package {[
              'ipxe',
              'ipxe-qemu',
              ]:
                  ensure => installed,
    }
    file {'/var/tftp/ipxe':
        ensure => link,
        target => '/usr/lib/ipxe/ipxe.pxe',
    }
    file {'/var/tftp/ipxe.qemu':
        ensure => link,
        target => '/usr/lib/ipxe/virtio-net.rom',
    }
}
