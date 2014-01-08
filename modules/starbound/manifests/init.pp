# Class: starbound::server
#
# configure starbound server from steam
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

class starbound::server (
    $user = 'steam',
    $path = '/home/steam/steam_apps/starbound',
    $steam_script_dir = '/home/steam/scripts',
    $steam_user       = false
    ) {
    if $steam_user {
        file {"${steam_script_dir}/update_starbound.steam":
            content => template('starbound/update_starbound.steam'),
            owner   => $user,
            mode    => 644,
        }
    }
    file { $path:
        ensure => directory,
        mode   => 644,
        owner  => $user,
    }
}
