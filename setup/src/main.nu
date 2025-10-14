#!/usr/bin/env nu

use std/log

use ./cli/files.nu *
use ./cli/packages.nu *
use ./cli/units.nu *
use ./fns *

# TODO: fix requirements
# currently -> pactree, chown, diff, unlink, ln

def main [config_file_rel_path: path] {
   build-config ($config_file_rel_path | path expand)
}

def "main install" [config_file_rel_path: path] {
   let config = build-config ($config_file_rel_path | path expand)

   install-packages $config.package_group_list
   spawn-files $config.file_spawn_list
   install-items $config.item_install_list
   enable-units $config.unit_group_list
}

def "main cleanup" [config_file_rel_path: path] {
   let config = build-config ($config_file_rel_path | path expand)

   cleanup-packages $config.package_group_list
   cleanup-units $config.unit_group_list
}
