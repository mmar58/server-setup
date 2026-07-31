Yes, absolutely! Nushell is not just a command prompt; it is a fully-fledged, structured scripting language. In Nushell, functions are actually called **Custom Commands**, and writing them is highly intuitive because of the language's focus on structured data.

Here is the best way to write, organize, and use functions and scripts in Nushell.

### 1. Writing Custom Commands (Functions)

To create a function in Nushell, you use the `def` keyword. You can define these directly in your terminal, inside your `config.nu`, or in a standalone script.

Here is the basic syntax with type hints and a default value:

```nu
# A simple command that greets a user
def greet [
    name: string        # A required string parameter
    age?: int           # An optional integer parameter (indicated by the ?)
    --shout (-s)        # A boolean flag (starts with --, optional short flag with -)
] {
    let base_greeting = $"Hello, ($name)!"
    
    let final_greeting = if $shout {
        $base_greeting | str upcase
    } else {
        $base_greeting
    }

    if ($age != null) {
        print $"($final_greeting) You are ($age) years old."
    } else {
        print $final_greeting
    }
}

```

**How to use it:**

* `greet "Alice"`
* `greet "Bob" 30`
* `greet --shout "Charlie"` or `greet -s "Charlie"`

### 2. Writing Standalone Scripts

If you want to automate a task, you can write your Nushell code in a file with a `.nu` extension (e.g., `build.nu`).

A script can contain multiple `def` commands, and you usually put the main execution logic at the bottom.

To run a script from your terminal, simply pass it to the `nu` executable:

```powershell
nu build.nu

```

**Best Practice for Scripts:** If you want your script to act like a native CLI tool, you can use the `def --env main []` or just `def main []` syntax. If a file has a `main` command, Nushell will automatically run it when you execute the file.

### 3. Creating Reusable Modules (The "Best" Way to Organize)

If you start building a lot of custom commands, putting them all in your `config.nu` will get messy fast. The best practice is to separate them into modules.

**Step A: Create a module file (e.g., `my_tools.nu`)**
Use the `export def` keyword to make the command available outside the file.

```nu
# inside my_tools.nu
export def "git clean-branches" [] {
    print "Cleaning up local git branches..."
    # Your git logic here
}

export def "sys-info" [] {
    sys | get host
}

```

**Step B: Import and use it**
In your terminal or inside your `config.nu`, you can import these commands using `use`:

```nu
use my_tools.nu *

```

*(The `*` imports everything, meaning you can now just type `sys-info` in your terminal. If you omit the `*`, you would run it by typing `my_tools sys-info`, which is great for preventing name collisions!)*

---

Do you have a specific PowerShell or Bash script you are currently trying to convert into Nushell, or are you just exploring the syntax right now?