export def spawn-files [files_to_spawn] {
   $files_to_spawn | each {|file_to_spawn|
      try {
         spawn-file $file_to_spawn
         apply-ownership $file_to_spawn.owner $file_to_spawn.group $file_to_spawn.target_file_abs_path
      } catch {|error|
         $error.rendered | print
      }
   } | ignore
}

export def install-items [items_to_install] {
   $items_to_install | each {|item_to_install|
      try {
         operate-item-install $item_to_install
         apply-ownership $item_to_install.owner $item_to_install.group $item_to_install.target_item_abs_path
      } catch {|error|
         $error.rendered | print
      }
   } | ignore
}

def spawn-file [file_to_spawn] {
   log info (
      $"checking file to spawn as user=($file_to_spawn.owner)" +
      $" with target=($file_to_spawn.target_file_abs_path)"
   )

   let target_item_abs_path_existing_type_or_null = (
      $file_to_spawn.target_file_abs_path | path type
   )

   match $target_item_abs_path_existing_type_or_null {
      dir => {
         log info $"spawning file at target=($file_to_spawn.target_file_abs_path)"
         rm -r $file_to_spawn.target_file_abs_path
         $file_to_spawn.content | save $file_to_spawn.target_file_abs_path
      }

      file => {
         let target_file = open --raw $file_to_spawn.target_file_abs_path

         if ($target_file == $file_to_spawn.content) {
            log info (
               $"skipping as target=($file_to_spawn.target_file_abs_path) matches with content"
            )

            return
         }

         log info $"spawning file at target=($file_to_spawn.target_file_abs_path)"
         rm $file_to_spawn.target_file_abs_path
         $file_to_spawn.content | save $file_to_spawn.target_file_abs_path
      }

      symlink => {
         log info $"spawning file at target=($file_to_spawn.target_file_abs_path)"
         unlink $file_to_spawn.target_file_abs_path
         $file_to_spawn.content | save $file_to_spawn.target_file_abs_path
      }

      null => {
         let target_parent_dir_abs_path = (
            $file_to_spawn.target_file_abs_path | path dirname
         )

         if not ($target_parent_dir_abs_path | path exists) {
            mkdir $target_parent_dir_abs_path
         }

         log info $"spawning file at target=($file_to_spawn.target_file_abs_path)"
         $file_to_spawn.content | save $file_to_spawn.target_file_abs_path
      }

      _ => {
         log error (
            $"skipped as not implemeted to" +
            $" target_type=($target_item_abs_path_existing_type_or_null)"
         )
      }
   }
}

def operate-item-install [item_to_install] {
   log info (
      $"checking file to install as user=($item_to_install.owner)" +
      $" with target=($item_to_install.target_item_abs_path)"
   )

   let source_item_abs_path_existing_type_or_null = $item_to_install.source_item_abs_path | path type
   let target_item_abs_path_existing_type_or_null = $item_to_install.target_item_abs_path | path type

   # wrapping it in a closure allows to early returns
   # as now it needs to check the correct ownership at the end
   match [
      $item_to_install.operation
      $source_item_abs_path_existing_type_or_null
      $target_item_abs_path_existing_type_or_null
   ] {
      # needs to be at the top so it allows me to use '_' more freely
      # this is because later on '_' will match everything except the conditions
      # already defined
      [_ null _] => {
         log error $"skipping source=($item_to_install.source_item_abs_path) does not exist"
      }

      # separator
      #
      [copy _ null] => {
         let target_parent_dir_abs_path = $item_to_install.target_item_abs_path | path dirname

         if not ($target_parent_dir_abs_path | path exists) {
            mkdir $target_parent_dir_abs_path
         }

         log info $"installing to target=($item_to_install.target_item_abs_path)"
         cp -r $item_to_install.source_item_abs_path $item_to_install.target_item_abs_path
      }

      [copy dir dir] => {
         if (
            diff -rq $item_to_install.target_item_abs_path $item_to_install.source_item_abs_path
         ) {
            log info (
               $"skipping as target=($item_to_install.target_item_abs_path) matches with source"
            )

            return
         }

         log info $"installing to target=($item_to_install.target_item_abs_path)"
         rm -r $item_to_install.target_item_abs_path
         cp -r $item_to_install.source_item_abs_path $item_to_install.target_item_abs_path
      }

      [copy file file] => {
         let target_file = open --raw $item_to_install.target_item_abs_path
         let source_file = open --raw $item_to_install.source_item_abs_path

         if ($target_file == $source_file) {
            log info (
               $"skipping as target=($item_to_install.target_item_abs_path) matches with source"
            )

            return
         }

         log info $"installing to target=($item_to_install.target_item_abs_path)"
         rm $item_to_install.target_item_abs_path
         cp $item_to_install.source_item_abs_path $item_to_install.target_item_abs_path
      }

      [copy symlink symlink] => {
         if (
            ($item_to_install.source_item_abs_path | path expand) ==
            ($item_to_install.target_item_abs_path | path expand)
         ) {
            log info (
               $"skipping as target=($item_to_install.target_item_abs_path) matches with source"
            )

            return
         }

         log info $"installing to target=($item_to_install.target_item_abs_path)"
         unlink $item_to_install.target_item_abs_path
         cp $item_to_install.source_item_abs_path $item_to_install.target_item_abs_path
      }

      [link _ null] => {
         if not (should-link $item_to_install) {
            log warning (
               $"skipping operation=($item_to_install.operation) as source=($item_to_install.source_item_abs_path) is not owned by ($item_to_install.owner)"
            )

            return
         }

         let target_parent_dir_abs_path = $item_to_install.target_item_abs_path | path dirname

         if not ($target_parent_dir_abs_path | path exists) {
            mkdir $target_parent_dir_abs_path
         }

         log info $"installing to target=($item_to_install.target_item_abs_path)"
         ln -s $item_to_install.source_item_abs_path $item_to_install.target_item_abs_path
      }

      [link _ dir] => {
         if not (should-link $item_to_install) {
            log warning (
               $"skipping operation=($item_to_install.operation) as source=($item_to_install.source_item_abs_path) is not owned by ($item_to_install.owner)"
            )

            return
         }

         log info $"installing to target=($item_to_install.target_item_abs_path)"
         rm -r $item_to_install.target_item_abs_path
         ln -s $item_to_install.source_item_abs_path $item_to_install.target_item_abs_path
      }

      [link _ file] => {
         if not (should-link $item_to_install) {
            log warning (
               $"skipping operation=($item_to_install.operation) as source=($item_to_install.source_item_abs_path) is not owned by ($item_to_install.owner)"
            )

            return
         }

         log info $"installing to target=($item_to_install.target_item_abs_path)"
         rm $item_to_install.target_item_abs_path
         ln -s $item_to_install.source_item_abs_path $item_to_install.target_item_abs_path
      }

      [link _ symlink] => {
         if not (should-link $item_to_install) {
            log warning (
               $"skipping operation=($item_to_install.operation) as source=($item_to_install.source_item_abs_path) is not owned by ($item_to_install.owner)"
            )

            return
         }

         if (
            ($item_to_install.target_item_abs_path | path expand) ==
            $item_to_install.source_item_abs_path
         ) {
            log info (
               $"skipping as target=($item_to_install.target_item_abs_path) matches with source"
            )

            return
         }

         log info $"installing to target=($item_to_install.target_item_abs_path)"
         unlink $item_to_install.target_item_abs_path
         ln -s $item_to_install.source_item_abs_path $item_to_install.target_item_abs_path
      }

      [_ _ _] => {
         log error (
            $"skipped as not implemented to following operation=($item_to_install.operation)" +
            $" source=($source_item_abs_path_existing_type_or_null)" +
            $" target=($target_item_abs_path_existing_type_or_null)"
         )
      }
   }
}

def apply-ownership [owner: string group: string target_item_abs_path: path] {
   if ($owner == $env.LOGNAME) {
      return
   }

   let target_item_owner = ls -lD $target_item_abs_path | get 0 | get user

   if ($target_item_owner == $owner) {
      return
   }

   chown -R $"($owner):($group)" $target_item_abs_path
}

# This is needed because it does not make sense to a user to have a symlink that they can not
# access.
def should-link [item_to_install] {
   let source_owner = (ls -lD $item_to_install.source_item_abs_path | get 0 | get user)
   $source_owner == $item_to_install.owner
}
