class vlogs::common (
    $manage_storage=true,
) {
    user { 'vlogs':
        system  => true,
        comment => 'VictoriaMetrics',
        home    => '/opt/vlogs',
    }
    file {
        [
            '/opt/vlogs',
            '/opt/vlogs/bin',
            '/opt/vlogs/tmp',
        ]:
        ensure  => 'directory',
        owner   => 'vlogs',
        group   => 'vlogs',
        mode    => "750",
        require => User['vlogs'],
    }
    if !defined(File['/var/lib/vlogs']) and $manage_storage {
        file { '/var/lib/vlogs':
            ensure => directory,
            owner => 'vlogs',
            group => 'vlogs',
            mode => '750',
        }

    }
    $version = '1.41.0'
    archive { '/opt/vlogs/server.tar.gz':
        source        => "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v${version}/victoria-logs-linux-amd64-v${version}.tar.gz",
        checksum      => 'a84447589d6283a420631fd243adabaf7b7d1abf13b1b6a4a7713c2a017bb968',
        checksum_type => 'sha256',
        extract       => true,
        extract_path  => '/opt/vlogs/bin',
        cleanup       => false, # so puppet doesn't re-download it, as it needs file to know whether checksum is current
        #creates       => '/opt/vlogs/bin/vmagent-prod',
        require       => File['/opt/vlogs/bin'],
    }
    archive { '/opt/vlogs/utils.tar.gz':
        source        => "https://github.com/VictoriaMetrics/VictoriaLogs/releases/download/v${version}/vlutils-linux-amd64-v${version}.tar.gz",
        checksum      => '6695a4621c42aa2f62b524eeab2885920c0a880c78d36fe55a363656aa0f0020',
        checksum_type => 'sha256',
        extract       => true,
        extract_path  => '/opt/vlogs/bin',
        cleanup       => false,
        #creates       => '/opt/vlogs/bin/vmstorage-prod',
        require       => File['/opt/vlogs/bin'],
    }
    [
        'victoria-logs',
        'vlagent',
        'vlogscli'
    ].each |$f| {
        file { "/opt/vlogs/bin/${f}": target => "/opt/vlogs/bin/${f}-prod" }
    }
}