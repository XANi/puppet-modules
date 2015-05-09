class user::common {
    $users = hiera_hash('users',{})
    $groups = hiera_hash('groups',{})

    create_resources('@user',$users)
    create_resources('@group',$groups)
}
