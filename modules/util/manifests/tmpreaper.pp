class util::tmpreaper {
    package { 'tmpreaper':
        ensure => absent
    }
    file {'/etc/tmpreaper': ensure => absent}
}