class util::shell {
    file {'/root/.bash_prompt':
        mode  => 644,
        owner => root,
        content => template('util/bash_prompt'),
    }
        file {'/root/.bashrc':
        mode  => 644,
        owner => root,
        content => template('util/bashrc'),
    }
}

