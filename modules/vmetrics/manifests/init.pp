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
    # remember to change checksums too!
    $version = '1.98.0'
    archive { '/opt/vmetrics/utils.tar.gz':
        source        => "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${version}/vmutils-linux-amd64-v${version}.tar.gz",
        checksum      => '5b7f47cd4b32a651bf501d33a5a12cc03477a9685f7d419f801a02c7e709411a',
        checksum_type => 'sha256',
        extract       => true,
        extract_path  => '/opt/vmetrics/bin',
        cleanup       => false, # so puppet doesn't re-download it, as it needs file to know whether checksum is current
        #creates       => '/opt/vmetrics/bin/vmagent-prod',
        require       => File['/opt/vmetrics/bin'],
    }
    archive { '/opt/vmetrics/cluster.tar.gz':
        source        => "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${version}/victoria-metrics-linux-amd64-v${version}-cluster.tar.gz",
        checksum      => 'a4ae99a637d79ad35ec86862c1b9892844ac846b88a84279f948bd326d6b4f68',
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

class vmetrics::storage (
    $path='/var/lib/vmetrics',
    $manage_dir=false,
    $retention="7d",
    $data_flush_interval="10s", # 10s is default
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
        subscribe => Archive['/opt/vmetrics/cluster.tar.gz'],
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

