export def is-package-a-dependency []: string -> bool {
   let package = $in
   let pactree_output_complete = pactree -rl $package | complete

   if ($pactree_output_complete | get exit_code | $in != 0) {
      return false
   }

   $pactree_output_complete | get stdout | lines | length | $in > 1
}

export def check-what-error [
   error
   texts_to_search: list<string>
]: nothing -> bool {
   $error.json
   | from json
   | get labels
   | get text
   | any {|text|
      $texts_to_search
      | any {|text_to_search|
         $text | str contains $text_to_search
      }
   }
}
