# Class: wireless::util
#
#   install some base packages for managing wifi
#
#
class wireless::util {
    package {'wireless-tools':
        ensure => installed,
    }
}

