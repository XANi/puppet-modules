class vmetrics::storage (
    $manage_dir=false,
    $retention="7d",
    $data_flush_interval="10s", # 10s is default
    $listen_addr = '0.0.0.0:8482',
    $vminsert_addr = '0.0.0.0:8400',
    $vmselect_addr = '0.0.0.0:8401',
) {
    include vmetrics::common
    $path='/var/lib/vmetrics'

    vmetrics::storage::instance { 'main':
        listen_addr         => $listen_addr,
        retention           => $retention,
        data_flush_interval => $data_flush_interval,
        vminsert_addr       => $vminsert_addr,
        vmselect_addr       => $vmselect_addr,
    }
}

define vmetrics::storage::instance(
    $data_flush_interval="1m",
    $retention="31d",
    $min_scrape_interval='10s',
    $memory_pct = 20,
    $listen_addr,
    $vminsert_addr,
    $vmselect_addr,
    $cache_memory_max = '1GB',

) {
    require vmetrics::common
    include vmetrics::storage
    $path=$::vmetrics::storage::path

    $data_path = "${path}/data-${title}"
    $service_name = "vmstorage-${title}"
    $instance = $title
    file { $data_path:
        ensure => directory,
        owner  => vmetrics,
        group  => vmetrics,
        mode   => "750",
    }
    systemd::service { $service_name:
        content => template('vmetrics/vmstorage.service'),
        notify => Service[$service_name],
    }
    service { $service_name:
        ensure => running,
        enable => true,
        subscribe => Archive['/opt/vmetrics/cluster.tar.gz'],
    }
}
