use ../utils *

export def enable-units [unit_groups] {
   $unit_groups | each {|unit_group|
      try {
         log info $"checking services with user=($unit_group.user) and dir_abs_path=($unit_group.dir_abs_path)"

         let units_enabled = (
            let units_enabled = get-units-enabled $unit_group.dir_abs_path;

            if $units_enabled == null {
               log error $"skipping as most likely permissions are insufficient"
               return
            } else {
               $units_enabled
            }
         )

         let units_to_enable = $unit_group.enable_list | where {|unit_to_enable|
            $unit_to_enable not-in $units_enabled
         }

         if ($units_to_enable | is-empty) {
            log info $"skipping as there is no services to enable"
            return
         }

         $units_to_enable | each {|unit_to_enable|
            log info $"attempting to enable service=($unit_to_enable) with user=($unit_group.user)"

            if (is-admin) and ($unit_group.user == root) {
               systemctl enable $unit_to_enable
            } else if (is-admin) {
               systemctl --user -M $"($unit_group.user)@" enable $unit_to_enable
            } else if ($unit_group.user == $env.LOGNAME) {
               systemctl --user enable $unit_to_enable
            } else {
               log error "skipped as there is no means to do so"
            }
         }
      } catch {|error|
         $error | print
      }
   } | ignore
}

export def cleanup-units [unit_groups] {
   $unit_groups | each {|unit_group|
      try {
         log info $"checking units with user=($unit_group.user) and dir_abs_path=($unit_group.dir_abs_path)"

         let units_enabled = (
            let enabled_units = get-units-enabled $unit_group.dir_abs_path;

            if $enabled_units == null {
               log error $"skipping as most likely permissions are insufficient"
               return
            } else {
               $enabled_units
            }
         )

         let units_ignore_list = $unit_group.enable_list | each --flatten {|unit_to_enable|
            if (is-admin) and ($unit_group.user == root) {
               systemctl list-dependencies --plain --no-pager $unit_to_enable
               | lines
               | str trim
               | where $it =~ '\.service$|\.socket$|\.timer$'
            } else if (is-admin) {
               systemctl --user -M $"($unit_group.user)@" list-dependencies --plain --no-pager $unit_to_enable
               | lines
               | str trim
               | where $it =~ '\.service$|\.socket$|\.timer$'
            } else if ($unit_group.user == $env.LOGNAME) {
               systemctl --user list-dependencies --plain --no-pager $unit_to_enable
               | lines
               | str trim
               | where $it =~ '\.service$|\.socket$|\.timer$'
            } else {
               log error "skipped as conditions are not fufilled"
               error make {msg: "i cant have this fail atm"}
            }
         }
         | uniq

         let units_to_disable = $units_enabled | where {|unit_to_enabled|
            (
               ($unit_to_enabled not-in $unit_group.enable_list) and
               ($unit_to_enabled not-in $units_ignore_list)
            )
         }

         if ($units_to_disable | is-empty) {
            log info $"skipping as there is no services to cleanup"
            return
         }

         $units_to_disable | each {|unit_to_disable|
            log info $"attempting to disable unit=($unit_to_disable) with user=($unit_group.user)"

            if (is-admin) and ($unit_group.user == root) {
               systemctl disable $unit_to_disable
            } else if (is-admin) {
               systemctl --user -M $"($unit_group.user)@" disable $unit_to_disable
            } else if ($unit_group.user == $env.LOGNAME) {
               systemctl --user disable $unit_to_disable
            } else {
               log error "skipped as there is no means to do so"
            }
         }
      } catch {|error|
         $error | print
      }
   } | ignore
}

def get-units-enabled [service_dir_abs_path: string] {
   let g = $"($service_dir_abs_path)/*.wants/*"

   try {
      ls ($g | into glob) | get name | each {|item|
         $item | path basename
      }
   } catch {|$error|
      if (check-what-error $error ["Permission denied"]) {
         return null
      } else if (check-what-error $error ["Pattern, file or folder not found"]) {
         return []
      } else {
         error make {msg: here}
      }
   }
}
