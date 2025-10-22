#!/usr/bin/env nu

# {"root@raphael": {files: [], packages: [], units: []}}

ls */**/*.toml
| each {|it| open $it.name }
| flatten
| each {|it| if $it.files? != null { $it } }
| flatten
| reduce -f {} {|file acc|
   $file.profiles | reduce -f $acc {|profile inner_acc|
      $inner_acc | upsert $profile {
         files: (
            $inner_acc
            | get -o $profile | get -o files
            | default []
            | append $file
         )

         # packages: (
         #    $inner_acc
         #    | get -o $profile | get -o units
         #    | default []
         #    |
         # )
      }
   }
} | to nuon
