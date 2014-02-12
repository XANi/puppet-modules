
class carton::common {
    package {'carton':
        ensure => installed,
    }
}


# Define: carton::app
#
# Deploy perl carton app
#
# Parameters:
#
# Actions:
#
# Requires:
#
#
# Sample Usage:
#
#
#
define carton::app (
    $dir,
    $user = 'root',
    )  {
    include carton::common
    Exec {
        path      => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        user      => $user,
        cwd       => $dir,
        logoutput => true,
    }
    exec {"carton-install-${title}":
        command => 'carton install >.installed',
        onlyif  => 'test -e .installed && test cpanfile -ot .installed',
    }
}
