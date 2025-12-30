# bird
# forked from https://github.com/XANi/puppet-bird

#### Table of Contents

1. [Overview](#overview)
3. [Setup - The basics of getting started with bird](#setup)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

Module for managing BIRD routing daemon configuration via puppet

## Module Description

Module takes as an input simple configuration hash and generates a snippet of BIRD configuration and if it is valid, reloads daemon

## Setup

By default defines will install current version of bird and run IPv4 daemon (ipv6 is WiP). For override either specify parameters via hiera/enc or specify it in class **before** any define like that:

    class {"bird":
        version => "installed",
        $service_ipv4 => true,
        $service_ipv6 => true,
        $router_id    => '1.2.3.4'
    }

Files are generated in `/etc/bird/v4.d` and `/etc/bird/v6.d` directories and included from main one

only "device" protocol is included in main file so minimal config would look something like that:

    # import direct routes
    bird::config {'direct':
        config => {
            "protocol direct" => [
                                  'interface "eth*"',
                                  ]
        }
    }
    # import all we get
    bird::config {'ospf-main':
        config => {
            'protocol ospf main' => [
                'import all',
                'export all',
                {'area 0.0.0.0' => {
                    "stub" => false,
                    'interface "eth2"' => [
                        "authentication none",
                    ],
                }}
             ],

            },
    }
    # export all to kernel. learn admin-added static routes. do not remove routes on restart
    bird::config{'kernel':
        config => {
            "protocol kernel" => [
                "learn",
                "persist",
                "graceful restart on",
                "import all",
                "export all",
            ]
        }
    }

# Reference

Underlying ruby code in template converts data structures into bird config:

* array will get converted into lines ending with ';', e.g. ['import all','export all'] will become

    import all;
    export all;

* hash with other hash or array as value gets converted into {}-enclosed block, e.g. `'interface "eth*"' => ['authentication none'] ` will become

    interface "eth*" {
        authentication none;
    };

* hash with string/int/bool as value will become single line, e.g. `stub => false` will become `stub no;`.
  * Non-number values will be in `""`
  * pure numbers will be unquoted.
  * `true` will be converted to `yes` while false to `no`.
  * `undef` will just use whole key as string (when you dont want the auto-quoting at all

** WARNING!!! ** due to how bird config works, `export all` and `export "all"` is **NOT** same (2nd one will trigger parse error). It is recommended to use arrays and hashes with arrays as values. It also guarantees constant order

## Limitations

Tested only under Debian 8 (Jessie)


## Development

Pull requests and bug reports welcome
