# Class: tinyvirt
#
#
#
# Parameters:
#
# Actions:
#
# Requires:
#
#
# Sample Usage:
#
#
#


class tinyvirt {
    vcsrepo {'/usr/src/tinyvirt':
        provider => git,
        source   => 'https://github.com/XANi/tinyvirt.git',
        revision => 'master',
    }
    carton::app { 'tinyvirt':
        dir     => '/usr/src/tinyvirt',
        require => Vcsrepo['/usr/src/tinyvirt']
    }
}
