use ../utils *

export def enable-unit-list [unit_group_list] {
   $unit_group_list | each {|unit_group|
      try {
         log info $"checking services with user=($unit_group.user) and dir_abs_path=($unit_group.dir_abs_path)"

         let unit_enabled_list = (
            let unit_enabled_list_or_null = get-unit-enabled-list-or-null $unit_group.dir_abs_path;

            if $unit_enabled_list_or_null == null {
               log error $"skipping as most likely permissions are insufficient"
               return
            } else {
               $unit_enabled_list_or_null
            }
         )

         let unit_enable_list = $unit_group.enable_list | where {|unit_enable|
            $unit_enable not-in $unit_enabled_list
         }

         if ($unit_enable_list | is-empty) {
            log info $"skipping as there is no services to enable"
            return
         }

         $unit_enable_list | each {|unit_enable|
            log info $"attempting to enable service=($unit_enable) with user=($unit_group.user)"

            if (is-admin) and ($unit_group.user == root) {
               systemctl enable $unit_enable
            } else if (is-admin) {
               systemctl --user -M $"($unit_group.user)@" enable $unit_enable
            } else if ($unit_group.user == $env.LOGNAME) {
               systemctl --user enable $unit_enable
            } else {
               log error "skipped as there is no means to do so"
            }
         }
      } catch {|error|
         $error | print
      }
   } | ignore
}

export def cleanup-service-list [unit_group_list] {
   $unit_group_list | each {|unit_group|
      try {
         log info $"checking units with user=($unit_group.user) and dir_abs_path=($unit_group.dir_abs_path)"

         let unit_enabled_list = (
            let unit_enabled_list_or_null = get-unit-enabled-list-or-null $unit_group.dir_abs_path;

            if $unit_enabled_list_or_null == null {
               log error $"skipping as most likely permissions are insufficient"
               return
            } else {
               $unit_enabled_list_or_null
            }
         )

         let units_ignore_list = $unit_group.enable_list | each {|unit_enable|
            if (is-admin) and ($unit_group.user == root) {
               systemctl list-dependencies --plain --no-pager $unit_enable
               | lines
               | str trim
               | where $it =~ '\.service$|\.socket$|\.timer$'
            } else if (is-admin) {
               systemctl --user -M $"($unit_group.user)@" list-dependencies --plain --no-pager $unit_enable
               | lines
               | str trim
               | where $it =~ '\.service$|\.socket$|\.timer$'
            } else if ($unit_group.user == $env.LOGNAME) {
               systemctl --user list-dependencies --plain --no-pager $unit_enable
               | lines
               | str trim
               | where $it =~ '\.service$|\.socket$|\.timer$'
            } else {
               log error "skipped as conditions are not fufilled"
               error make {msg: "i cant have this fail atm"}
            }
         }
         | flatten
         | uniq

         let unit_disable_list = $unit_enabled_list | where {|unit_enabled|
            (
               ($unit_enabled not-in $unit_group.enable_list) and
               ($unit_enabled not-in $units_ignore_list)
            )
         }

         if ($unit_disable_list | is-empty) {
            log info $"skipping as there is no services to cleanup"
            return
         }

         $unit_disable_list | each {|unit_disable|
            log info $"attempting to disable unit=($unit_disable) with user=($unit_group.user)"

            if (is-admin) and ($unit_group.user == root) {
               systemctl disable $unit_disable
            } else if (is-admin) {
               systemctl --user -M $"($unit_group.user)@" disable $unit_disable
            } else if ($unit_group.user == $env.LOGNAME) {
               systemctl --user disable $unit_disable
            } else {
               log error "skipped as there is no means to do so"
            }
         }
      } catch {|error|
         $error | print
      }
   } | ignore
}

def get-unit-enabled-list-or-null [service_dir_abs_path: string] {
   let g = $"($service_dir_abs_path)/*.wants/*"

   # if (glob $g | is-empty) {
   #    return []
   # }

   try {
      ls ($g | into glob) | get name | each {|item|
         $item | path basename
      }
   } catch {|$error|
      if (check-what-error $error ["Permission denied"] | is-empty) {
         return null
      } else if (check-what-error $error ["Pattern, file or folder not found"] | is-empty) {
         return []
      } else {
         error make {msg: here}
      }
   }
}
