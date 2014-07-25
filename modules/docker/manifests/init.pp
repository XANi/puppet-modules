class docker::common {
    package { 'docker.io':
        ensure => installed,
    }
}

class docker {
    include docker::common
    service { 'docker.io':
        ensure => running,
        enable => true,
    }
}
