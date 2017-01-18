class core {
    include core::apt::base
}

class core::apt::base {
    create_resources("@apt::source",hiera('repos'))
}
