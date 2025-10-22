#!/usr/bin/env nu

# Reads *.toml recursively and does stuff.
def main [
   --config-dir (-c): path = . # full path to config directory
] {
   build-config $config_dir
}

def 'main install' [
   profiles: list<string> # [user@hostname user2@hostname2 some-other-profile-name]
] { }

def build-config [config_dir: path]: nothing -> record {
   let target = $config_dir | path join '*' '**' '*.toml' | into glob

   let raw_config = ls $target | each --flatten {|it| open $it.name }
   let raw_file_configs = $raw_config | each --flatten {|it| if $it.files? != null { $it.files } }
   let raw_package_configs = $raw_config | each --flatten {|it| if $it.packages? != null { $it.packages } }
   let raw_unit_configs = $raw_config | each --flatten {|it| if $it.units? != null { $it.units } }

   let config = $raw_file_configs
   | reduce -f {} {|raw_file file_configs|
      $raw_file.profiles
      | reduce -f $raw_file_configs {|raw_profile inner_file_configs|
         $inner_file_configs
         | upsert ([$raw_profile files] | into cell-path) {
            $inner_file_configs
            | get -o $raw_profile
            | get -o files
            | default []
            | append ($raw_file | reject profiles)
         }
      }
   }

   let config = $raw_package_configs
   | reduce -f $config {|raw_package package_configs|
      $raw_package.profiles
      | reduce -f $raw_package_configs {|raw_profile inner_package_configs|
         $inner_package_configs
         | upsert ([$raw_profile packages] | into cell-path) {
            $inner_package_configs
            | get -o $raw_profile
            | get -o packages
            | default []
            | append ($raw_package | reject profiles)
         }
      }
   }

   let config = $raw_unit_configs | reduce -f $config {|raw_unit unit_configs|
      $raw_unit.profiles | reduce -f $raw_unit_configs {|raw_profile inner_unit_configs|
         $inner_unit_configs | upsert $raw_unit {
            units: (
               $inner_unit_configs
               | get -o $raw_profile | get -o units
               | default []
               | append $raw_unit
            )
         }
      }
   }

   $config
}
