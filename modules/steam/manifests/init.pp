# simple wrapper for running batch jobs
class steam::batch (
    $user = 'steam',
    $home = '/home/steam',
    $steam_script_dir = '/home/steam/scripts',
) {
    file { "${home}/run_batch":
        content => template('steam/run_batch'),
        mode    => 755,
        owner   => $user,

    }
}
