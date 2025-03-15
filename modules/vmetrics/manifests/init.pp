# URLs
#
# https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#url-format
# * http://<vminsert>:8480/insert/<accountID>/
# * http://<vminsert>:8480/insert/<accountID>/influx/api/v2/write
# * http://<vminsert>:8480/insert/<accountID>/influx/write
# * http://<vminsert>:8480/insert/<accountID>/datadog/api/v1/series
# * http://<vminsert>:8480/insert/<accountID>/prometheus/api/v1/import/prometheus
# * http://<vmselect>:8481/select/<accountID>/prometheus/
#

class vmetrics::common (
    $manage_storage=true,
) {
    # TODO autoinstall
    user { 'vmetrics':
        system  => true,
        comment => 'VictoriaMetrics',
        home    => '/opt/vmetrics',
    }
    file {
        [
            '/opt/vmetrics',
            '/opt/vmetrics/bin',
            '/opt/vmetrics/tmp',
        ]:
        ensure  => 'directory',
        owner   => 'vmetrics',
        group   => 'vmetrics',
        mode    => "750",
        require => User['vmetrics'],
    }
    if !defined(File['/var/lib/vmetrics']) and $manage_storage {
        file { '/var/lib/vmetrics':
            ensure => directory,
            owner => 'vmetrics',
            group => 'vmetrics',
            mode => '750',
        }

    }
    # remember to change checksums too!
    $version = '1.112.0'
    archive { '/opt/vmetrics/utils.tar.gz':
        source        => "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${version}/vmutils-linux-amd64-v${version}.tar.gz",
        checksum      => '57fc797702f43764e26f7f3c6c394dc19ca5a6baf504a598f047d64f2de9bff0',
        checksum_type => 'sha256',
        extract       => true,
        extract_path  => '/opt/vmetrics/bin',
        cleanup       => false, # so puppet doesn't re-download it, as it needs file to know whether checksum is current
        #creates       => '/opt/vmetrics/bin/vmagent-prod',
        require       => File['/opt/vmetrics/bin'],
    }
    archive { '/opt/vmetrics/cluster.tar.gz':
        source        => "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${version}/victoria-metrics-linux-amd64-v${version}-cluster.tar.gz",
        checksum      => '03958ce68263e1ff47a7ea5656da5468922c56ebc0a5c320ca4fe8a210729f40',
        checksum_type => 'sha256',
        extract       => true,
        extract_path  => '/opt/vmetrics/bin',
        cleanup       => false,
        #creates       => '/opt/vmetrics/bin/vmstorage-prod',
        require       => File['/opt/vmetrics/bin'],
    }
    [
        'vmagent',
        'vmalert',
        'vmauth',
        'vmbackup',
        'vmctl',
        'vminsert',
        'vmrestore',
        'vmselect',
        'vmstorage',
    ].each |$f| {
        file { "/opt/vmetrics/bin/${f}": target => "/opt/vmetrics/bin/${f}-prod" }
    }
}


class vmetrics::select (
    Array $storage_nodes,
    Integer $replication_factor=1,
    $path = '/var/lib/vmetrics',
) {
    systemd::service { 'vmselect':
        content => template('vmetrics/vmselect.service'),
        notify => Service['vmselect'],
    }
    service { "vmselect":
        ensure => running,
        enable => true,
        subscribe => Archive['/opt/vmetrics/cluster.tar.gz'],
    }
    file { "${path}/cache":
        ensure => directory,
        owner  => vmetrics,
        group  => vmetrics,
        mode   => "750",
    }
}

class vmetrics::insert (
    Array $storage_nodes,
    Integer $replication_factor=1,
) {
    systemd::service { 'vminsert':
        content => template('vmetrics/vminsert.service'),
        notify => Service['vminsert'],
    }
    service { "vminsert":
        ensure => running,
        enable => true,
        subscribe => Archive['/opt/vmetrics/cluster.tar.gz'],
    }
}

class vmetrics::collectd2metrics  {
    systemd::service { 'collectd2metrics':
        content => template('vmetrics/collectd2metrics.service'),
        notify => Service['collectd2metrics'],
    }
    service { "collectd2metrics":
        ensure => running,
        enable => true,
    }
    file { '/etc/collectd2metrics.yaml':
        content => template('vmetrics/collectd2metrics.yaml'),
    }
        
}

class vmetrics::snapshot::common {
    file { '/opt/vmetrics/bin/vmsnapshot.sh':
        source => 'puppet:///modules/vmetrics/vmstorage_snapshot.sh',
        mode   => '755',
        owner => 'root',
    }
}
define vmetrics::snapshot (
    $port,
) {
    include vmetrics::snapshot::common
    cron { "vmetrics-snapshot-${title}":
        command => "/opt/vmetrics/bin/vmsnapshot.sh ${port} ${title}",
        hour    => 1,
        minute  => fqdn_rand(59, $title),
        user => 'vmetrics',
    }
}
