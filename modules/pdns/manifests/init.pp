class pdns::server {
    package {'pdns-server':
        ensure => installed
    }
}

define pdns::backend ($backend = $title) {
    package {"pdns-backend-${backend}":
        ensure => installed,
    }
}
