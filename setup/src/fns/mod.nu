export def collect-config-file-abs-paths [config_file_abs_path: path]: nothing -> list<path> {
   mut config_file_abs_paths_to_process = [$config_file_abs_path]
   mut config_file_abs_paths_collected = []

   while ($config_file_abs_paths_to_process | is-not-empty) {
      let config_file_abs_path_to_process = $config_file_abs_paths_to_process | first
      $config_file_abs_paths_to_process = $config_file_abs_paths_to_process | skip 1

      if (
         $config_file_abs_paths_collected | any {|config_file_abs_path_collected|
            $config_file_abs_path_collected == $config_file_abs_path_to_process
         }
      ) {
         continue
      }

      $config_file_abs_paths_collected = (
         $config_file_abs_paths_collected | append $config_file_abs_path_to_process
      )

      let config_file_rel_paths = open $config_file_abs_path_to_process | get -o include | default []
      let config_file_dir_path_to_process = $config_file_abs_path_to_process | path dirname

      let config_file_abs_paths_found = $config_file_rel_paths
      | each {|config_file_rel_path|
         $config_file_dir_path_to_process
         | path join $config_file_rel_path
         | path expand
      }

      $config_file_abs_paths_to_process = (
         $config_file_abs_paths_to_process | append $config_file_abs_paths_found
      )
   }

   $config_file_abs_paths_collected
}

export def build-config [
   config_file_rel_path: path
]: nothing -> record<package_groups: list<record<from: string, name: string, ignore: bool>>, files_to_spawn: list<record<owner: string, target_file_abs_path: path, content: string>>, items_to_install: list<record<operation: string, owner: string, source_item_abs_path: path, target_item_abs_path: path>>, unit_groups: list<record<user: string, dir_abs_path: string, enable_list: list<string>>>> {
   let config_file_abs_paths = collect-config-file-abs-paths $config_file_rel_path

   let config_groups_raw = $config_file_abs_paths | each {|config_file_abs_path|
      {
         config_file_rel_path: $config_file_abs_path
         config_raw: (open $config_file_abs_path)
      }
   }

   let files_to_spawn = $config_groups_raw.config_raw | each {|config_raw|
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

   let items_to_install = $config_groups_raw | each {|config_group_raw|
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

   let package_groups = $config_groups_raw | each {|config_group_raw|
      let config_dir_rel_path = $config_group_raw.config_file_rel_path | path dirname

      $config_group_raw.config_raw
      | get -o packages
      | default []
      | each {|package_raw_group|
         let dir_abs_path = if ($package_raw_group.path? == null) {
            null
         } else {
            $config_dir_rel_path | path join $package_raw_group.path | path expand
         }

         {
            from: $package_raw_group.from
            name: $package_raw_group.name
            ignore: $package_raw_group.ignore?
            dir_abs_path: $dir_abs_path
         }
      }
   } | flatten | uniq

   let duplicated_packages = $package_groups.name | uniq -d

   if ($duplicated_packages | is-not-empty) {
      error make {
         msg: "Duplicate package name with slight fields variants is not allowed."
         help: $"The following package(s) are duplicated: ($duplicated_packages | str join ', ')"
      }
   }

   let unit_groups = $config_groups_raw.config_raw | each {|config_raw|
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
      files_to_spawn: $files_to_spawn
      items_to_install: $items_to_install
      package_groups: $package_groups
      unit_groups: $unit_groups
   }
}
