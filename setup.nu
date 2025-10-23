#!/usr/bin/env nu

# Reads *.toml recursively and does stuff.
def main [
   --config-dir (-c): path = . # full path to config directory
] {
   build-config2 $config_dir
}

def 'main install' [
   profiles: list<string> # [user@hostname user2@hostname2 some-other-profile-name]
] { }

def build-config [config_dir: path]: nothing -> record {
   let target = $config_dir | path join '*' '**' '*.toml' | into glob

   let raw_config = ls $target | each --flatten {|it| open $it.name }

   let raw_file_configs = $raw_config
   | each --flatten {|it| if $it.files? != null { $it.files } }

   let raw_package_configs = $raw_config
   | each --flatten {|it| if $it.packages? != null { $it.packages } }

   let raw_unit_configs = $raw_config
   | each --flatten {|it| if $it.units? != null { $it.units } }

   let config = $raw_file_configs
   | reduce -f {} {|raw_file file_configs|
      $raw_file.profiles
      | reduce -f $file_configs {|raw_profile inner_file_configs|
         let path = [$raw_profile files] | into cell-path

         let files = (
            $inner_file_configs
            | get -o $raw_profile
            | get -o files
            | default []
            | append {
               source: $raw_file.source
               target: $raw_file.target
               action: $raw_file.action
               chmod: $raw_file.chmod
               owner: $raw_file.owner
               group: $raw_file.group
            }
         )

         $inner_file_configs | upsert $path $files
      }
   }

   let config = $raw_package_configs
   | reduce -f $config {|raw_package package_configs|
      $raw_package.profiles
      | reduce -f $package_configs {|raw_profile inner_package_configs|
         let path = [$raw_profile packages install] | into cell-path

         let existing_packages_to_install = (
            $inner_package_configs
            | get -o $raw_profile
            | get -o packages
            | get -o install
            | default []
         )

         let normalized_packages_to_install = (
            $raw_package.install
            | each {|package|
               {
                  from: $package.from
                  name: $package.name
                  ignore: ($package.ignore? | default false)
                  path: $package.path?
               }
            }
         )

         let merged_packages_to_install = (
            $existing_packages_to_install
            | append $normalized_packages_to_install
         )

         $inner_package_configs | upsert $path $merged_packages_to_install
      }
   }

   let config = $raw_unit_configs
   | reduce -f $config {|raw_unit unit_configs|
      $raw_unit.profiles
      | reduce -f $unit_configs {|raw_profile inner_unit_configs|
         let path = [$raw_profile units] | into cell-path

         let units = (
            $inner_unit_configs
            | get -o $raw_profile
            | get -o units
            | default []
            | append {
               enable: $raw_unit.enable?
               mask: $raw_unit.mask?
            }
         )

         $inner_unit_configs | upsert $path $units
      }
   }

   $config
}

def build-config2 [config_dir: path]: nothing -> any {
   let target = $config_dir | path join '*' '**' '*.toml' | into glob

   let config = ls $target
   | get name
   | reduce -f {} {|raw_config_file_rel_path config|
      let raw_config_file_abs_path = $raw_config_file_rel_path | path expand
      let raw_config = open $raw_config_file_abs_path

      let config = do {
         if $raw_config.files? == null {
            return $config
         }

         $raw_config.files
         | reduce -f $config {|raw_file config|
            $raw_file.profiles
            | reduce -f $config {|raw_profile config|
               let files = $config
               | get -o $raw_profile
               | get -o files
               | default []

               let files = $files
               | append {
                  source: $raw_file.source
                  target: $raw_file.target
                  action: $raw_file.action
                  chmod: $raw_file.chmod
                  owner: $raw_file.owner
                  group: $raw_file.group
               }

               $config | upsert ([$raw_profile files] | into cell-path) $files
            }
         }
      }

      let config = do {
         if $raw_config.packages? == null {
            return $config
         }

         $raw_config.packages
         | reduce -f $config {|raw_package config|
            $raw_package.profiles
            | reduce -f $config {|raw_profile config|
               let packages = $config
               | get -o $raw_profile
               | get -o packages
               | default []

               let packages = $packages
               | append (
                  $raw_package.install
                  | each {|package|
                     {
                        from: $package.from
                        name: $package.name
                        ignore: ($package.ignore? | default false)
                        path: $package.path?
                     }
                  }
               )

               $config
               | upsert ([$raw_profile packages] | into cell-path) $packages
            }
         }
      }

      let config = do {
         if $raw_config.units? == null {
            return $config
         }

         $raw_config.units
         | reduce -f $config {|raw_unit config|
            $raw_unit.profiles
            | reduce -f $config {|raw_profile config|
               mut config = $config

               if $raw_unit.enable? != null {
                  let units_to_enable = $config
                  | get -o $raw_profile
                  | get -o units
                  | get -o enable
                  | default []

                  let units_to_enable = $units_to_enable
                  | append $raw_unit.enable

                  $config = $config | upsert ([$raw_profile units enable] | into cell-path) $units_to_enable
               }

               if $raw_unit.mask? != null {
                  let units_to_mask = $config
                  | get -o $raw_profile
                  | get -o units
                  | get -o mask
                  | default []

                  let units_to_mask = $units_to_mask
                  | append $raw_unit.mask

                  $config = $config | upsert ([$raw_profile units mask] | into cell-path) $units_to_mask
               }

               $config
            }
         }
      }

      $config
   }

   $config
}
