class user::common {
    $users = lookup('users',undef,undef,{})
    $groups = lookup('groups',undef,undef,{})

    create_resources('@user',$users)
    create_resources('@group',$groups)
}
