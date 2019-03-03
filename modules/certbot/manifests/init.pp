# need to manually run certbot with email first
class certbot::common {
    file { '/usr/local/bin/get_a_cert.sh':
        source => "puppet:///modules/certbot/get_a_cert.sh",
        mode   => "755",
    }
    if !defined(File['/etc/pki']) {
        file { '/etc/pki':
            ensure => directory,
            owner  => root,
            mode   => '711',
        }
    }
    file { '/etc/pki/certbot':
        ensure => directory,
        owner  => root,
        mode   => '711',
    }
    package {'certbot': ensure => latest}
}

define certbot::cert (
    $main_domain,
    $extra_domain,
    $owner = 'root',
    $group = 'root',
    $mode  = '600',
)   {
    include certbot::common
    $domains = inline_template('<%= Array([@main_domain, @extra_domain]).flatten.join(" ") %>')
    cron{"certbot_${title}":
        command => "/usr/local/bin/get_a_cert.sh ${domains}",
        weekday => fqdn_rand(6),
        hour    => fqdn_rand(6),
        minute  => fqdn_rand(59),
    }
    file { "/etc/pki/certbot/${title}.pem":
        source => "/etc/letsencrypt/live/${main_domain}/certandkey.pem",
        notify => $notify,
    }


}