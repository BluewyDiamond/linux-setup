use ../utils *

export def install-packages [package_groups] {
   let packages_installed = pacman -Qq | lines

   let std_package_groups_for_install = $package_groups | where {|package_group|
      $package_group.from == "std" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   }

   let aur_package_groups_for_install = $package_groups | where {|package_group|
      $package_group.from == "aur" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   }

   let local_package_groups_for_install = $package_groups | where {|package_group|
      $package_group.from == "lcl" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   }

   (
      _install-packages
      $std_package_groups_for_install
      $packages_installed
      "std"

      {|missing_std_package_groups|
         let missing_std_packages = $missing_std_package_groups
         | each {|missing_std_package_group|
            $missing_std_package_group.name
         }

         try {
            pacman -S ...$missing_std_packages
         } catch {|$error|
            $error.rendered | print
         }
      }
   )

   (
      _install-packages
      $aur_package_groups_for_install
      $packages_installed
      "aur"

      {|missing_aur_package_groups|
         let missing_aur_packages = $missing_aur_package_groups
         | each {|missing_aur_package_group|
            $missing_aur_package_group.name
         }

         try {
            paru -S --aur ...$missing_aur_packages
         } catch {|$error|
            $error.rendered | print
         }
      }
   )

   (
      _install-packages
      $local_package_groups_for_install
      $packages_installed
      "local"

      {|missing_local_package_groups|
         let missing_local_package_paths = $missing_local_package_groups
         | each {|missing_local_package_group|
            $missing_local_package_group.dir_abs_path
         }

         try {
            paru -Bi ...$missing_local_package_paths
         } catch {|$error|
            $error.rendered | print
         }
      }
   )
}

def _install-packages [
   package_groups_for_install
   packages_installed: list<string>
   label: string
   on_install: closure
] {
   log info $"checking ($label) packages to install"

   let missing_package_groups = $package_groups_for_install | where {|package_group_for_install|
      $package_group_for_install.name not-in $packages_installed
   }

   if ($missing_package_groups | is-empty) {
      log info $"skipping as there is no ($label) packages to install"
      return
   }

   log info $"installing ($label) packages"
   do $on_install $missing_package_groups
}

export def cleanup-packages [package_groups] {
   log info 'checking for packages to cleanup'
   let installed_packages = pacman -Qqee | lines

   let std_packages_for_install = $package_groups | where {|package_group|
      $package_group.from == "std" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   } | each {|std_package_group_for_install| $std_package_group_for_install.name }

   let aur_packages_for_install = $package_groups | where {|package_group|
      $package_group.from == "aur" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   } | each {|aur_package_group_for_install| $aur_package_group_for_install.name }

   let local_packages_for_install = $package_groups | where {|package_group|
      $package_group.from == "lcl" and ($package_group.ignore_or_null == null or $package_group.ignore_or_null == false)
   } | each {|local_package_group_for_install| $local_package_group_for_install.name }

   let ignore_packages_for_install = $package_groups | where {|package_group|
      $package_group.ignore_or_null != null and $package_group.ignore_or_null == true
   } | each {|ignore_package_group_for_install| $ignore_package_group_for_install.name }

   let packages_for_install = [
      ...$std_packages_for_install
      ...$aur_packages_for_install
      ...$local_packages_for_install
      ...$ignore_packages_for_install
   ]

   let unlisted_packages = $installed_packages | par-each {|installed_package|
      if ($installed_package | is-package-a-dependency) {
         null
      } else if ($installed_package not-in $packages_for_install) {
         $installed_package
      } else {
         null
      }
   } | compact

   if ($unlisted_packages | is-not-empty) {
      log info 'cleaning up packages'
      pacman -Rns ...$unlisted_packages
   } else {
      log info 'skipping as there is no packages to cleanup'
   }
}
