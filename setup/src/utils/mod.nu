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
   item_list: list = []
]: any -> list<any> {
   let input = $in
   mut found_item_list = $item_list
   mut item_to_process_list = [$input]

   while ($item_to_process_list | is-not-empty) {
      let current_item = $item_to_process_list | first
      $item_to_process_list = $item_to_process_list | skip 1

      if (not (($current_item | describe) =~ "record|table")) {
         continue
      }

      let on_record_or_table_result = (do $on_record_or_table $current_item)
      $found_item_list = $found_item_list | append [$on_record_or_table_result]

      let current_item_values = $current_item | values
      $item_to_process_list = $item_to_process_list | append $current_item_values
   }

   $found_item_list | flatten
}

export def check-what-error [error label_text_list: list<string>] {
   $error.json | from json | get labels | where {|label|
      $label.text in $label_text_list
   }
}
