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
        subscribe => Archive['/opt/vmetrics/cluster.tar.gz'],
    }
}
define vmetrics::agent::scrape (
    $url,
    $instance = $title,
    $insecure_tls = true,
    $metric_relabel_configs = [],
) {
    $scrape_cfg = [{
        job_name   => "s-${title}",
        tls_config => { insecure_skip_verify => $insecure_tls },
        static_configs => [
            {
                targets => [ $url ],
                labels => {
                    instance => $instance,
                    host => $hostname,
                }
            }
        ],
        metric_relabel_configs=>$metric_relabel_configs,
    }
    ]
    file { "/etc/vmagent/scrape.d/${title}.yaml":
        content => inline_template('<%= YAML.dump(@scrape_cfg) %>'),
        notify => Service['vmagent'],
    }
}