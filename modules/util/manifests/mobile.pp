class util::mobile::laptop {
    package {[
              'network-manager',
              'network-manager-gnome',
              ]:
                  ensure => installed,
    }
}
