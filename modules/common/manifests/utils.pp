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
         'bwm-ng',
         ]:
             ensure => installed,
    }
}
