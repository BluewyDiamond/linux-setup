#!/usr/bin/env nu

const script_file_abs_path = path self .

let mshell_bin_abs_path = $script_file_abs_path | path join 'build' 'main.js'
let build_script_file_abs_path = $script_file_abs_path | path join 'scripts' 'build.ts'

def main [] { }

def "main build" [] {
   bun $build_script_file_abs_path
}

def "main run" [] {
   if not ($mshell_bin_abs_path | path exists) {
      main build
   }

   load-env {
      LD_PRELOAD: /usr/lib/libgtk4-layer-shell.so
   }

   exec gjs -m $mshell_bin_abs_path
}

def "main types" [] {
   let js_ags_dir_abs_path = "/usr/share/ags/js"
   let js_gnim_dir_abs_path = "/usr/share/ags/js/node_modules/gnim"
   let node_modules_dir_abs_path = ($script_file_abs_path)/node_modules
   let node_module_ags_dir_abs_path = ($script_file_abs_path)/node_modules/ags
   let node_module_gnim_dir_abs_path = ($script_file_abs_path)/node_modules/gnim
   let girs_dir_abs_path = ($script_file_abs_path)/@girs

   ls $js_ags_dir_abs_path
   ls $js_gnim_dir_abs_path

   let ensure_dir_exists = {|path: path|
      if ($path | path type | $in != dir) {
         rm -r $path
      }

      if not ($path | path exists) {
         mkdir $path
      }
   }

   do $ensure_dir_exists $node_modules_dir_abs_path

   if ($node_module_ags_dir_abs_path | path exists) {
      rm -r $node_module_ags_dir_abs_path
   }

   if ($node_module_gnim_dir_abs_path | path exists) {
      rm -r $node_module_gnim_dir_abs_path
   }

   ln -s $js_ags_dir_abs_path $node_module_ags_dir_abs_path
   ln -s $js_gnim_dir_abs_path $node_module_gnim_dir_abs_path

   if ($girs_dir_abs_path | path exists) {
      rm -r $girs_dir_abs_path
   }

   (
      bunx
      -y @ts-for-gir/cli generate '*'
      --ignore Gtk3 --ignore Astal3
      --ignoreVersionConflicts
      --outdir $girs_dir_abs_path
      -g /usr/local/share/gir-1.0
      -g /usr/share/gir-1.0
      -g '/usr/share/*/gir-1.0'
   )
}
