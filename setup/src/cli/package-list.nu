use ../utils *

export def install-package-list [package_group_list] {
   let package_installed_list = pacman -Qq | lines

   let package_group_std_install_list = $package_group_list | where {|package_group|
      $package_group.from == "std" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   }

   let package_group_aur_install_list = $package_group_list | where {|package_group|
      $package_group.from == "aur" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   }

   let package_group_local_install_list = $package_group_list | where {|package_group|
      $package_group.from == "lcl" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   }

   (
      _install-package-list
      $package_group_std_install_list
      $package_installed_list
      "std"

      {|package_group_std_missing_list|
         let package_std_missing = $package_group_std_missing_list
         | each {|package_group_std_missing|
            $package_group_std_missing.name
         }

         try {
            pacman -S ...$package_std_missing
         } catch {|$error|
            $error.rendered | print
         }
      }
   )

   (
      _install-package-list
      $package_group_aur_install_list
      $package_installed_list
      "aur"

      {|package_group_aur_missing_list|
         let package_aur_missing = $package_group_aur_missing_list
         | each {|package_group_aur_missing|
            $package_group_aur_missing.name
         }

         try {
            paru -S --aur ...$package_aur_missing
         } catch {|$error|
            $error.rendered | print
         }
      }
   )

   (
      _install-package-list
      $package_group_local_install_list
      $package_installed_list
      "local"

      {|package_group_local_missing_list|
         let package_local_path_missing = $package_group_local_missing_list
         | each {|package_group_local_missing|
            $package_group_local_missing.dir_abs_path
         }

         try {
            paru -Bi ...$package_local_path_missing
         } catch {|$error|
            $error.rendered | print
         }
      }
   )
}

def _install-package-list [
   package_group_install_list
   package_installed_list: list<string>
   label: string
   on_install: closure
] {
   log info $"checking ($label) packages to install"

   let package_group_missing_list = $package_group_install_list | where {|package_group_install|
      $package_group_install.name not-in $package_installed_list
   }

   if ($package_group_missing_list | is-empty) {
      log info $"skipping as there is no ($label) packages to install"
      return
   }

   log info $"installing ($label) packages"
   do $on_install $package_group_missing_list
}

# this could definetly be handled cleanly with a callback

def install-std-package-list [
   package_std_wanted_list: list<string>
   package_installed_list: list<string>
] {
   log info 'checking std packages to install'

   let package_std_missing_list = $package_std_wanted_list | where {|package_std_wanted|
      $package_std_wanted not-in $package_installed_list
   }

   if ($package_std_missing_list | is-empty) {
      log info 'skipping as there is no std packages to install'
      return
   }

   try {
      log info 'installing std packages'
      sudo pacman -S ...$package_std_missing_list
   } catch {|error|
      $error.rendered | print
   }
}

def install-aur-package-list [
   package_aur_wanted_list: list<string>
   package_installed_list: list<string>
] {
   log info 'checking aur packages to install'

   let package_aur_missing_list = $package_aur_wanted_list | where {|package_aur_wanted|
      $package_aur_wanted not-in $package_installed_list
   }

   if ($package_aur_missing_list | is-empty) {
      log info 'skipping as there is no aur packages to install'
      return
   }

   try {
      log info 'installing aur packages'
      paru -S --aur ...$package_aur_missing_list
   } catch {|error|
      $error.rendered | print
   }
}

def install-local-package-list [
   package_local_abs_path_wanted_list: list<string>
   package_installed_list: list<string>
] {
   log info 'checking local packages to install'

   let package_local_abs_path_missing_list = $package_local_abs_path_wanted_list
   | where {|package_local_abs_wanted|
      ($package_local_abs_wanted | path basename) not-in $package_installed_list
   }

   if ($package_local_abs_path_missing_list | is-empty) {
      log info 'skipping as there is no local packages to install'
      return
   }

   try {
      log info 'installing local packages'
      paru -Bi ...$package_local_abs_path_missing_list
   } catch {|error|
      $error.rendered | print
   }
}

export def cleanup-package-list [package_group_list] {
   log info 'checking for packages to cleanup'
   let package_installed_list = pacman -Qqee | lines

   let package_std_install_list = $package_group_list | where {|package_group|
      $package_group.from == "std" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   } | each {|package_group_std_install| $package_group_std_install.name }

   let package_aur_install_list = $package_group_list | where {|package_group|
      $package_group.from == "aur" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   } | each {|package_group_aur_install| $package_group_aur_install.name }

   let package_local_install_list = $package_group_list | where {|package_group|
      $package_group.from == "lcl" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   } | each {|package_group_local_install| $package_group_local_install.name }

   let package_ignore_install_list = $package_group_list | where {|package_group|
      $package_group.ignore_or_null != null and $package_group.ignore_or_null == true
   } | each {|package_group_ignore_install| $package_group_ignore_install.name }

   let package_install_list = [
      ...$package_std_install_list
      ...$package_aur_install_list
      ...$package_local_install_list
      ...$package_ignore_install_list
   ]

   let package_unlisted_list = $package_installed_list | par-each {|package_installed|
      if ($package_installed | is-package-a-dependency) {
         null
      } else if ($package_installed not-in $package_install_list) {
         $package_installed
      } else {
         null
      }
   } | compact

   if ($package_unlisted_list | is-not-empty) {
      log info 'cleaning up packages'
      pacman -Rns ...$package_unlisted_list
   } else {
      log info 'skipping as there is no packages to cleanup'
   }
}
