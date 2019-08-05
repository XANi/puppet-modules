class core::suspend::disable {
    file { '/etc/initramfs-tools/conf.d/resume':
        content => "RESUME=none\n"
    }

}
