
class mosquitto::client {
    ensure_packages(['mosquitto-clients'])
}

class mosquitto::server (
    Boolean $allow_anonymous = false,
    Variant[Bool[false],String] $persistent_client_expiration = "90d",
    Variant[Bool[false],String] $password_file = "/etc/mosquitto/passwd",
    Variant[Bool[false],String] $server_cert,
){
    ensure_packages(['mosquitto'])
    include mosquitto::client

    file { '/etc/mosquitto/conf.d/1000-general.conf':
        owner => mosquitto,
        mode => "640",
        content => template('mosquitto-general.conf')
    }
    service { 'mosquitto':
        ensure => running,
        enable => true,
    }


}