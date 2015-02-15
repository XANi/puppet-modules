class pdns::server {
    package {'pdns':
        ensure => installed
    }
}

define pdns::backend ($backend = $title) {
    package {"pdns-backend-${backend}":
        ensure => installed,
    }
}
