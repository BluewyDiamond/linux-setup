#!/usr/bin/env nu

const script_path = path self .

# IMPORTANT
# This script contains relative paths thus it is important for the script to be placed correctly.
def main [] { }

def "main build" [] {
   bun ($script_path)/scripts/build.ts
}

def "main run" [] {
   load-env {
      LD_PRELOAD: /usr/lib/libgtk4-layer-shell.so
   }

   exec gjs -m ($script_path)/build/main.js
}

def "main types" [] {
   let js_ags_abs_path = "/usr/share/ags/js"
   let js_gnim_abs_path = "/usr/share/ags/js/node_modules/gnim"
   let node_modules_abs_path = ($script_path)/node_modules
   let node_module_ags_abs_path = ($script_path)/node_modules/ags
   let node_module_gnim_abs_path = ($script_path)/node_modules/gnim
   let girs_abs_path = ($script_path)/@girs

   ls $js_ags_abs_path
   ls $js_gnim_abs_path

   let ensure_dir_exists = {|path: path|
      if ($path | path type | $in != dir) {
         rm -r $path
      }

      if not ($path | path exists) {
         mkdir $path
      }
   }

   do $ensure_dir_exists $node_modules_abs_path

   if ($node_module_ags_abs_path | path exists) {
      rm -r $node_module_ags_abs_path
   }

   if ($node_module_gnim_abs_path | path exists) {
      rm -r $node_module_gnim_abs_path
   }

   ln -s $js_ags_abs_path $node_module_ags_abs_path
   ln -s $js_gnim_abs_path $node_module_gnim_abs_path

   if ($girs_abs_path | path exists) {
      rm -r $girs_abs_path
   }

   (
      bunx
      -y @ts-for-gir/cli generate '*'
      --ignore Gtk3 --ignore Astal3
      --ignoreVersionConflicts
      --outdir $girs_abs_path
      -g /usr/local/share/gir-1.0
      -g /usr/share/gir-1.0
      -g '/usr/share/*/gir-1.0'
   )
}
