class utils::tmpreaper {
    ensure_packages(['tmpreaper'])
    file { '/etc/tmpreaper':
        mode => "644",
        owner => "root",
        content => template('util/tmpreaper.conf')
    }
}