# set of tools needed to make deb packages

class util::deb::pkgmaker {
    package { [
               'dh-make',
               'debhelper',
               'fakeroot',
               'lintian',]:
    }
}
