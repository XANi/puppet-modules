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
) {
    # TODO autoinstall
    user { 'vmetrics':
        system  => true,
        comment => 'VictoriaMetrics',
        home    => '/opt/vmetrics',
    }
    file { '/opt/vmetrics/bin':
        ensure  => 'directory',
        owner   => 'vmetrics',
        group   => 'vmetrics',
        mode    => "750",
        require => User['vmetrics'],
    }
    # remember to change checksums too!
    $version = '1.89.1'
    archive { '/opt/vmetrics/utils.tar.gz':
        source        => "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${version}/vmutils-linux-amd64-v${version}.tar.gz",
        checksum      => '967ac15c48874fba2e0ee673b6d1437566590fc85fce46bdbff47c9029f3a9af',
        checksum_type => 'sha256',
        extract       => true,
        extract_path  => '/opt/vmetrics/bin',
        creates       => '/opt/vmetrics/bin/vmagent-prod',
        cleanup       => true,
        require       => File['/opt/vmetrics/bin'],
    }
    archive { '/opt/vmetrics/cluster.tar.gz':
        source        => "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${version}/victoria-metrics-linux-amd64-v${version}-cluster.tar.gz",
        checksum      => '9b5e53054607f758205e978befd53be49d6eee28c03151d749684e0aa673feeb',
        checksum_type => 'sha256',
        extract       => true,
        extract_path  => '/opt/vmetrics/bin',
        cleanup       => true,
        creates       => '/opt/vmetrics/bin/vmstorage-prod',
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
    }
    file { "${path}/cache":
        ensure => directory,
        owner  => vmetrics,
        group  => vmetrics,
        mode   => "750",
    }
}

class vmetrics::storage (
    $path='/var/lib/vmetrics',
    $manage_dir=false,
    $retention="7d"
) {
    if $manage_dir {
        file { $path:
            ensure => directory,
            owner  => vmetrics,
            group  => vmetrics,
            mode   => "750",
        }
    }
    $pprof_auth_key =
    file { "${path}/data":
        ensure => directory,
        owner  => vmetrics,
        group  => vmetrics,
        mode   => "750",
    }
    systemd::service { 'vmstorage':
        content => template('vmetrics/vmstorage.service'),
        notify => Service['vmstorage'],
    }
    service { "vmstorage":
        ensure => running,
        enable => true,
    }
    include vmetrics::common
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
    }
}

class vmetrics::agent (
) {
    include vmetrics::common
    file { '/var/lib/vmetrics/agent':
        ensure => directory,
        owner  => vmetrics,
        group  => vmetrics,
        mode   => "750",
    }
    systemd::service { 'vmagent':
        content => template('vmetrics/vmagent.service'),
        notify => Service['vmagent'],
    }
    service { "vmagent":
        ensure => running,
        enable => true,
    }
}

class vmetrics::collectd2metrics {
    systemd::service { 'collectd2metrics':
        content => template('vmetrics/collectd2metrics.service'),
        notify => Service['collectd2metrics'],
    }
    service { "collectd2metrics":
        ensure => running,
        enable => true,
    }
}

