export def is-package-a-dependency []: string -> bool {
   let package = $in
   let pactree_output_complete = pactree -rl $package | complete

   if ($pactree_output_complete | get exit_code | $in != 0) {
      return false
   }

   $pactree_output_complete | get stdout | lines | length | $in > 1
}

export def collect-values-by-key [
   on_record_or_table: closure
   items: list = []
]: any -> list<any> {
   let input = $in
   mut found_items = $items
   mut items_to_process = [$input]

   while ($items_to_process | is-not-empty) {
      let current_item = $items_to_process | first
      $items_to_process = $items_to_process | skip 1

      if (not (($current_item | describe) =~ "record|table")) {
         continue
      }

      let on_record_or_table_result = (do $on_record_or_table $current_item)
      $found_items = $found_items | append [$on_record_or_table_result]

      let current_item_values = $current_item | values
      $items_to_process = $items_to_process | append $current_item_values
   }

   $found_items | flatten
}

export def check-what-error [error texts_to_search: list<string>]: nothing -> bool {
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
