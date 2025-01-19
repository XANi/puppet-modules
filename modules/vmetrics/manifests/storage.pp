class vmetrics::storage (
    $path='/var/lib/vmetrics',
    $manage_dir=false,
    $retention="7d",
    $data_flush_interval="10s", # 10s is default
    $listen_addr = '0.0.0.0:8482',
    $vminsert_addr = '0.0.0.0:8400',
    $vmselect_addr = '0.0.0.0:8401',
) {
    include vmetrics::common
    if $manage_dir {
        file { $path:
            ensure => directory,
            owner  => vmetrics,
            group  => vmetrics,
            mode   => "750",
        }
    }

    include vmetrics::storage::common
    vmetrics::storage::instance { 'main':
        path                => $path,
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

) {
    require vmetrics::common
    require vmetrics::storage
    $path=$::vmetrics::storage::path

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
        subscribe => Archive['/opt/vmetrics/cluster.tar.gz'],
    }
}
