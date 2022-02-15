class util::mobile::laptop {
    package {[
              'network-manager',
              'network-manager-gnome',
              ]:
                  ensure => installed,
    }
    puppet::lazyfact{'laptop': val => true}
}
