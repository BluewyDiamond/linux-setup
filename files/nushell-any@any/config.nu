# [ Env ]
#
$env.config.show_banner = false

# [[ Path ]]
#
let path_list = [
   ($env.HOME | path join ".cargo" "bin")
   ($env.HOME | path join ".local" "bin")
]

$env.PATH = ($env.PATH | append $path_list)

# [[ XDG ]]
#
$env.XDG_CONFIG_HOME = ($env.HOME | path join ".config")
$env.XDG_DATA_HOME = ($env.HOME | path join ".local" "share")
$env.XDG_STATE_HOME = ($env.HOME | path join ".local" "state")
$env.XDG_CACHE_HOME = ($env.HOME | path join ".cache")

# [[ xdg-ninja ]]
#
$env.GOPATH = ($env.XDG_DATA_HOME | path join "go")
$env.GTK2_RC_FILES = ($env.XDG_CONFIG_HOME | path join "gtk-2.0" "gtkrc")
$env.NODE_REPL_HISTORY = ($env.XDG_STATE_HOME | path join "node_repl_history")
$env.NPM_CONFIG_INIT_MODULE = ($env.XDG_CONFIG_HOME | path join "npm" "config" "npm-init.js")
$env.NPM_CONFIG_CACHE = ($env.XDG_CACHE_HOME | path join "npm")
$env.NPM_CONFIG_TMP = ($env.XDG_RUNTIME_DIR | path join "npm")
$env.RUSTUP_HOME = ($env.XDG_DATA_HOME | path join "rustup")
$env.WINEPREFIX = ($env.XDG_DATA_HOME | path join "wine")

# [[ Other ]]
#
$env.EDITOR = "nvim"

# [ Alias ]
#
# replacing built-in commands kinda broken rn
# while technically working,
# the alias --help is calling the replacer --help
# this only happens when replacing built-in commands
alias nu-clear = clear

# This is an alias. More help available at the link below.
# https://www.nushell.sh/commands/docs/clear.html
#
# Clear the terminal.
def clear [
   --keep-scrollback (-k)
] {
   nu-clear --keep-scrollback=$keep_scrollback
   tput cup (term size | get rows)
}

def --wrapped aura [...args] {
   let cmd = $args | reduce --fold ["paru"] {|arg cmd|
      if not ($arg =~ "^-[a-zA-Z]+$") {
         $cmd | append $arg
      } else {
         $arg | split chars | skip 1 | reduce --fold $cmd {|char flag|
            $flag | append (
               match $char {
                  "S" => ["-S" "--repo"]
                  "A" => ["-S" "--aur"]
                  "W" => ["-S"]
                  _ => [$"-($char)"]
               }
            )
         }
      }
   }

   run-external ...$cmd
}

alias nu-ls = ls

# The original built-in command 'ls' has been renamed to 'nu-ls'.
#
# List the filenames, sizes, and modification times of items in a directory.
def ls [
   --hidden (-H) # Show hidden files
   --long (-l) # Get all available columns for each entry (slower; columns are platform-dependent)
   --short-names (-s) # Only print the file names, and not the path
   --full-paths (-f) # display paths as absolute paths
   --du (-d) # Display the apparent directory size ("disk usage") in place of the directory metadata size
   --directory (-D) # List the specified directory itself instead of its contents
   --mime-type (-m) # Show mime-type in type column instead of 'file' (based on filenames only; files' contents are not examined)
   --plain (-p) # Show plain files
   --threads (-t) # Use multiple threads to list contents. Output will be non-deterministic.
   ...patterns: oneof<glob, string> # The glob pattern to use.
]: [nothing -> table] {
   let patterns = if ($patterns | is-empty) {
      [.]
   }

   mut output = (
      nu-ls
      --all=true
      --long=true
      --short-names=$short_names
      --full-paths=$full_paths
      --du=$du
      --directory=$directory
      --mime-type=$mime_type
      --threads=$threads
      ...$patterns
   )

   if (not $long) {
      $output = $output | select name type mode user group size modified
   }

   if $hidden and not $plain {
      $output = $output | par-each {|item|
         if ($item.name | str starts-with '.') { $item }
      }
   } else if $plain and not $hidden {
      $output = $output | par-each {|item|
         if not ($item.name | str starts-with '.') { $item }
      }
   } else if $plain and $hidden {
      error make {msg: "hidden and plain flags can not coexist"}
   }

   paint-ls $output
}

def paint-ls [table] {
   $table
   | par-each {|row|
      let name = if $row.type == dir {
         $"(ansi blue_bold)($row.name)(ansi reset)"
      } else if $row.type == symlink {
         $"(ansi cyan_bold)($row.name)(ansi reset)"
      } else if ($row.mode | str contains 'x') {
         $"(ansi red_bold)($row.name)(ansi reset)"
      } else {
         null
      }

      if $name == null {
         return $row
      }

      $row | upsert name $name
   }
}

# [ Autostart ]
#
# for autoloading scripts
let nu_autoload = ($nu.data-dir | path join "vendor/autoload")
mkdir $nu_autoload

# [[ Prompt (Starship) ]]
#
do {||
   if (which starship | is-empty) {
      return
   }

   let starship_init_file_abs_path = ($nu_autoload | path join "starship.nu")
   let starship_init_file = starship init nu

   if (
      ($starship_init_file_abs_path | path exists) and
      ($starship_init_file == (open --raw $starship_init_file_abs_path))
   ) {
      return
   }

   $starship_init_file | save -f $starship_init_file_abs_path
}

# [[ Visuals ]]
#
# wait for window animations (usually lasts around 0.15sec)
# + consider the time it takes to reach here
sleep 0.15sec
tput cup (term size | get rows)
fastfetch -c ($env.HOME | path join ".config" "fastfetch" "wezterm.jsonc")
