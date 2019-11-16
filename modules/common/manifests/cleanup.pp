
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
