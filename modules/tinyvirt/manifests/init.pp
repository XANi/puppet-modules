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


class tinyvirt (
    $repo_url = 'https://github.com/XANi/tinyvirt.git',
)  {
    vcsrepo {'/usr/src/tinyvirt':
        provider => git,
        source   => $repo_url,
        revision => 'master',
    }
    carton::app { 'tinyvirt':
        dir     => '/usr/src/tinyvirt',
        require => Vcsrepo['/usr/src/tinyvirt']
    }
}
