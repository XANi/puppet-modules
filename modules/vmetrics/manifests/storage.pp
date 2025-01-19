
class vmetrics::storage (
    $path='/var/lib/vmetrics',
    $manage_dir=false,
    $retention="7d",
    $data_flush_interval="10s", # 10s is default
) {
    $instance = 'main'
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


define vmetrics::storage::instance(
    $data_flush_interval="1m",
    $retention="31d",
    $min_scrape_interval='10s',
    $memory_pct = 20,
    $listen_addr,
    $vminsert_addr,
    $vmselect_addr,

) {
    require vmetrics::common
    $path='/var/lib/vmetrics'
    $data_path = "${path}/data-${title}"
    $service_name = "vmstorage-${title}"
    $instance = $title
    $pushmetrics_url = $vmetrics::common::pushmetrics_url
    file { $data_path:
        ensure => directory,
        owner  => victoriametrics,
        group  => victoriametrics,
        mode   => "750",
    }
    systemd::service { $service_name:
        content => template('vmetrics/vmstorage.service'),
        notify => Service[$service_name],
    }
    service { $service_name:
        ensure => running,
        enable => true,
    }
}
