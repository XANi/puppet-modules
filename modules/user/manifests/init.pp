class user::common {
    $users = hiera_hash('users',{})
    $system_users = hiera_hash('users_system',{})
    create_resources('@user',$users)
}
