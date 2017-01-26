
class syncthing  {
    realize Apt::Source['syncthing']
    package {'syncthing':
        ensure => 'latest';
    }
}


define syncthing::instance {
    include syncthing
    file {"/etc/systemd/system/syncthing-${title}.service":
        content => template('syncthing/systemd'),
        mode => "644",
    }
    service {"syncthing-${title}":
        enable => true,
	provider => 'systemd',
        require => File["/etc/systemd/system/syncthing-${title}.service"]
    }
}
