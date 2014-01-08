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
    $steam_user       = false,
    $validate         = false, # validate on each update
    ) {
    if $steam_user {
        include steam::batch
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
