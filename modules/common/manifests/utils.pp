# Class: common::utils
#
# some utils that should be on (almost) every server
#
class common::utils {
    include util::etckeeper
    package {
        [
         'bridge-utils',
         'bwm-ng',
         'curl',
         'ethtool',
         'lsof',
         'lvm2',
         'nmap',
         'psmisc',
         'screen',
         'sudo',
         'tcpdump',
         'tree',
         'mtr-tiny',
         'xfsprogs',
         'zile',
         ]:
             ensure => installed,
    }
}

# remove unwanted crap
class common::cleanup {
    # these are outdated crappy and unwanted
    package {[
              'manpages-pl',
              'manpages-pl-dev',
              ]:
                  ensure => absent,
    }
}
