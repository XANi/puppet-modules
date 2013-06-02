
class ntp::client ($server = hiera('ntp_server','pl.pool.ntp.org')) {
    package { 'ntpdate':
        ensure => installed;
    }
    $command = "/usr/sbin/ntpdate -t 60 ${server}"
    file { '/etc/cron.hourly/ntpdate':
        mode    => 755,
        owner   => root,
        content => "#!/bin/sh\n${command} >/dev/null 2>&1\n",
        notify  => Exec['update-time'],
    }
    exec {'update-time':
        logoutput   => true,
        command     => $command,
        refreshonly => true,
    }

}
