class vmetrics::agent (
    $url = 'http://127.0.0.1:8480/insert/100:0/prometheus/api/v1/write'
) {
    include vmetrics::common
    $var = '/var/lib/vmetrics/agent'
    $etc = '/etc/vmagent'
    File {
        owner => vmetrics,
        group => vmetrics,
        mode => "0650"
    }
    file { [
        $var,
        "${etc}",
        "${etc}/scrape.d",
    ] :
        ensure => directory,
        owner  => vmetrics,
        group  => vmetrics,
        mode   => "750",
    }
    file { "${var}/.nobackup":
        content => "*\n";
    }
    file { "${etc}/scrape.yaml":
        content => template('vmetrics/scrape.yaml'),
        mode => "640"
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
    $interval = "10s",
) {
    include vmetrics::agent
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
        scrape_interval => $interval,
        metric_relabel_configs=>$metric_relabel_configs,
    }
    ]
    file { "/etc/vmagent/scrape.d/${title}.yaml":
        content => inline_template('<%= YAML.dump(@scrape_cfg) %>'),
        notify => Service['vmagent'],
    }
}

define vmetrics::agent::haproxy (
    $url,
    $instance = $title
) {
    vmetrics::agent::scrape { "haproxy-${title}":
        instance               => $instance,
        url                    => $url,
        metric_relabel_configs => [
            {
                'if'     => '{__name__ = "haproxy_server_uweight"}',
                'action' => 'drop',
            },
            {
                'if'     => '{__name__ = "haproxy_build_info"}',
                'action' => 'drop',
            },
            { # we don't need type of check on metric, just up/down is enough
                'if'     => '{__name__ = "haproxy_backend_agg_check_status"}',
                'action' => 'drop',
            },
            { # we don't need type of check on metric, just up/down is enough
                'if'     => '{__name__ = "haproxy_server_check_status"}',
                'action' => 'drop',
            },
            { # aggregated status is enough for metrics, we have checks to monitor fails
                'if'     => '{__name__ = "haproxy_server_status"}',
                'action' => 'drop',
            },
            {
                'if'     => '{__name__ =~ "haproxy_process_max.*"}',
                'action' => 'drop',
            },
            {
                'if'     => '{__name__ =~ "haproxy_process_hard_max.*"}',
                'action' => 'drop',
            },
            { # scrape stats are irrelevant TODO scrape seems internal and dropping doesn't seem to work ;/
                'if'     => '{__name__ =~ "scrape.*"}',
                'action' => 'drop',
            },
            { # job name is irrelevant if not debugging
                'action' => 'labeldrop',
                'regex'  => "job",
            }
        ],
    }
}