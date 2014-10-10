# Class: common::utils
#
# some utils that should be on (almost) every server
#
class common::utils {
    package {
        [
         'screen',
         'zile',
         'nmap',
         'etckeeper',
         'psmisc',
         'curl',
         'bwm-ng',
         'bridge-utils',
         'tcpdump',
         'lsof',
         'ethtool',
         'tree',
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
