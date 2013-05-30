
class nullmailer (
    $remote,
    $mailname = $fqdn,
    $adminaddr = false,
    $maildomain = $domain,
) {
    package { 'nullmailer':
        ensure => installed,
    }
    file {'/etc/mailname':
        content => $mailname,
        mode    => 644,
        owner   => root,
    }
    if $adminaddr {
        file {'/etc/nullmailer/adminaddr':
            content => $adminaddr,
            mode    => 644,
            owner   => root,
        }
    }
    file {'/etc/nullmailer/remotes':
        content => $remote,
        mode    => 600,
        owner   => root,
    }
    file {'/etc/nullmailer/defaultdomain':
        content => $maildomain,
        mode    => 644,
        owner   => root,
    }
}

