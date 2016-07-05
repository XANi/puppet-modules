class ruby::fpm (
    $user  = 'nobody',
    $group = 'nogroup',
    $version = 'master',
    $install_path = '/var/fpm',
    ) {
    include ruby
    file { $install_path:
        ensure => directory,
        owner  => $user,
        mode   => "750",
    }
    vcsrepo { $install_path:
        source   => "https://github.com/jordansissel/fpm",
        ensure   => present,
        provider => 'git',
        user     => $user,
        revision => $version,
    }
}
