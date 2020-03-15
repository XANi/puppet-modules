
class mosquitto::client {
    ensure_packages(['mosquitto-clients'])
}

class mosquitto::server (
    Boolean $allow_anonymous = false,
    Variant[Boolean[false],String] $persistent_client_expiration = "90d",
    Variant[Boolean[false],String] $password_file = "/etc/mosquitto/passwd",
    Boolean $manage_password_file = true,
    Variant[Boolean[false],String] $server_cert = false,
){
    ensure_packages(['mosquitto'])
    include mosquitto::client

    file { '/etc/mosquitto/conf.d/1000-general.conf':
        owner => mosquitto,
        mode => "640",
        content => template('mosquitto/general.conf')
    }
    if $password_file and $manage_password_file {
        concat { $password_file:
            owner  => mosquitto,
            group  => mosquitto,
            mode   => "0600",
            notify => Class['mosquitto'],
        }
    }

    service { 'mosquitto':
        ensure => running,
        enable => true,
    }


}