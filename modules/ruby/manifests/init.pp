# just a basic ruby deps, enougth to do "bundle install"

class ruby (
    $ruby_version = '2.1',
)  {
    package {"ruby${version}":
        alias  => 'ruby',
        ensure => latest,
    }
    package {"bundler":
        ensure => latest,
    }
}
