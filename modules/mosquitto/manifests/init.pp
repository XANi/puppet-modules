
class mosquitto::client {
    ensure_packages(['mosquitto-clients'])
}

class mosquitto::server (
    $listener = "1883",
    Variant[Boolean[false],String,Integer] $ws_listener = false,
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
        content => template('mosquitto/general.conf'),
        notify => Service['mosquitto'],
    }
    if $password_file and $manage_password_file {
        concat { $password_file:
            owner  => mosquitto,
            group  => mosquitto,
            mode   => "0600",
            notify => Service['mosquitto'],
        }
        concat::fragment { "${password_file}_header":
            target => $password_file,
            content => "# puppet managed file\n",
        }
    }

    service { 'mosquitto':
        ensure => running,
        enable => true,
    }


}