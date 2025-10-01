export def collect-config-file-abs-path-list [config_file_abs_path: path]: nothing -> list<path> {
   mut config_file_abs_path_to_process_list = [$config_file_abs_path]
   mut config_file_abs_path_collected_list = []

   while ($config_file_abs_path_to_process_list | is-not-empty) {
      let config_file_abs_path_to_process = $config_file_abs_path_to_process_list | first
      $config_file_abs_path_to_process_list = $config_file_abs_path_to_process_list | skip 1

      if (
         $config_file_abs_path_collected_list | any {|config_file_abs_path_collected|
            $config_file_abs_path_collected == $config_file_abs_path_to_process
         }
      ) {
         continue
      }

      $config_file_abs_path_collected_list = (
         $config_file_abs_path_collected_list | append $config_file_abs_path_to_process
      )

      let config_file_rel_path_list = open $config_file_abs_path_to_process | get -o include | default []
      let config_file_dir_path_to_process = $config_file_abs_path_to_process | path dirname

      let config_file_abs_path_found_list = $config_file_rel_path_list
      | each {|config_file_rel_path|
         $config_file_dir_path_to_process
         | path join $config_file_rel_path
         | path expand
      }

      $config_file_abs_path_to_process_list = (
         $config_file_abs_path_to_process_list | append $config_file_abs_path_found_list
      )
   }

   $config_file_abs_path_collected_list
}

export def build-config [
   config_file_rel_path: path
]: nothing -> record<package_group_list: list<record<from: string, name: string, ignore: bool>>, file_spawn_list: list<record<owner: string, target_file_abs_path: path, content: string>>, item_install_list: list<record<operation: string, owner: string, source_item_abs_path: path, target_item_abs_path: path>>, unit_group_list: list<record<user: string, dir_abs_path: string, enable_list: list<string>>>> {
   let config_file_abs_path_list = collect-config-file-abs-path-list $config_file_rel_path

   let config_group_raw_list = $config_file_abs_path_list | each {|config_file_abs_path|
      {
         config_file_rel_path: $config_file_abs_path
         config_raw: (open $config_file_abs_path)
      }
   }

   let file_spawn_list = $config_group_raw_list.config_raw | each {|config_raw|
      $config_raw
      | get -o files-spawn
      | default []
      | each {|file_spawn|
         {
            owner: $file_spawn.owner
            group: $file_spawn.group
            target_file_abs_path: $file_spawn.target
            content: $file_spawn.content
         }
      }
   } | flatten | uniq

   let item_install_list = $config_group_raw_list | each {|config_group_raw|
      let config_dir_rel_path = $config_group_raw.config_file_rel_path | path dirname

      $config_group_raw.config_raw
      | get -o items-install
      | default []
      | each {|item_install_raw|
         {
            operation: $item_install_raw.operation
            owner: $item_install_raw.owner
            group: $item_install_raw.group

            source_item_abs_path: (
               $config_dir_rel_path
               | path join $item_install_raw.source
               | path expand
            )

            target_item_abs_path: $item_install_raw.target
         }
      }
   } | flatten | uniq

   let package_group_list = $config_group_raw_list | each {|config_group_raw|
      let config_dir_rel_path = $config_group_raw.config_file_rel_path | path dirname

      $config_group_raw.config_raw
      | get -o packages
      | default []
      | each {|package_raw_group|
         let dir_abs_path_or_null = if ($package_raw_group.path? == null) {
            null
         } else {
            $config_dir_rel_path | path join $package_raw_group.path | path expand
         }

         {
            from: $package_raw_group.from
            name: $package_raw_group.name
            ignore_or_null: $package_raw_group.ignore?
            dir_abs_path_or_null: $dir_abs_path_or_null
         }
      }
   } | flatten | uniq

   let package_duplicate_list = $package_group_list.name | uniq -d

   if ($package_duplicate_list | is-not-empty) {
      error make {
         msg: "Duplicate package name with slight fields variants is not allowed."
         help: $"The following package(s) are duplicated: ($package_duplicate_list | str join ', ')"
      }
   }

   let unit_group_list = $config_group_raw_list.config_raw | each {|config_raw|
      $config_raw
      | get -o units
      | default []
      | each {|unit|
         {
            user: ($unit | get user)
            dir_abs_path: ($unit | get path)
            enable_list: ($unit | get enable)
         }
      }
   }
   | flatten
   | group-by {|row|
      $"($row.user):($row.dir_abs_path)"
   }
   | values
   | each {|group|
      {
         user: $group.0.user
         dir_abs_path: $group.0.dir_abs_path
         enable_list: ($group | get enable_list | flatten | uniq)
      }
   }

   {
      file_spawn_list: $file_spawn_list
      item_install_list: $item_install_list
      package_group_list: $package_group_list
      unit_group_list: $unit_group_list
   }
}
