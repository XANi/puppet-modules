# Class: common::utils
#
# some utils that should be on (almost) every server
#
class common::utils {
    include util::etckeeper
    package {
        [
            'aptitude',
            'bc',
            'bridge-utils',
            'bwm-ng',
            'bzip2',
            'curl',
            'ethtool',
            'locales-all', # so various tools can use it and non-english letters in console work
            'lsof',
            'lvm2',
            'mtr-tiny',
            'ncdu',
            'nmap',
            'psmisc',
            'sudo',
            'tcpdump',
            'tmux',
            'tree',
            'xfsprogs',
            'debsecan',
            'apt-transport-https',
            'zile',
         ]:
             ensure => installed,
    }
}

