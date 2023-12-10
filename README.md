# Log
![large_icon](https://github.com/albinaask/GodotLogger/assets/11806563/09e98637-b81f-402f-b8fb-73e3dc201986)


The simple solution for all your logging needs in GDScript. Note that this is a fork from the original GodotLogger that has been reworked, polished and extended upon.

# Features

## Original

- Has a basic logger to print out Nodes,Objects,Arrays,Dictionarys etc.
- Has support for easily reading env vars & cmd line args.

## New for the fork

- Adds multiple log streams so you can control the log level independently for different parts of your project.
- Adds a fatal log level that causes your project to crash in a way that you can control.
- Adds comments to updated parts of the plugin.
- Adds options in top of the log stream.
- Adds shorthand methods for debug & error.
- Adds err_cond_... methods for quick error checking.
- Adds a scripted breakpoint (optional in setting) so errors freeze the execution and shows relevant info in the godot debugger.
- Adds support for multiple log files.
- Adds a test scene that can be used as an example of how the plugin can be used.

## Example of usage

![code_sample](https://github.com/albinaask/GodotLogger/assets/11806563/2b9490d6-646b-40ac-9e8d-b511b027e018)

## Example of output

![output_sample](https://github.com/albinaask/GodotLogger/assets/11806563/0e122e02-f8dd-4a6d-8ba8-e92c021a3c7b)

# Installation

1. Install from asset lib or drag the addons/logger folder from the downloaded zip into the project folder.
2. Enable plugin (Project > Project Settings > Plugins > Click on 'Enable' plugin checkbox)
3. Reload editor. (For some reason Godot shows cryptic error messages, which disappears on reload).
4. Done! 

# Usage
You can either use the predefined, "main" logger, which is accessed through a global singelton that can be reached from anywhere within your project (you may have to change the load order of the autoloads to make it work in other singletons).

You simply put a log message where you'd otherwise put a print:
```
func do_something():
	var math = 1+1
 	Log.info("The answer is: " + str(math))
```

## Levels
There are five different levels for logging in Log. They are debug, info, warning, error & fatal.

Each have a calling method which are:
```
Log.debug("some message")
Log.info("some message")
Log.warn("some message")
Log.error("some message")
Log.fatal("some message")
```
The levels debug and error has shorthands that do identical things:
```
Log.dbg("some message")
Log.err("some message")
```

These methods are defined in the class LogStream. You call them like above, they all print a formatted string to the console and to the file if desired. Then there are more functionality to the levels warning, error and fatal. On the level warning(use `Log.warn("Message")`), a warning is pushed to the Godot debug menu, which shows a yellow marker when run past by the engine. The error level(`Log.error("Message")` or `Log.err("Message")`) shows a similar red tag. It then also by default (can be configured) halt the execution in debug environments, so the error can be debugged. 

GDScript has a built-in error handler that basically tries to skip the code that throws an error, this is really nice since your application does not necessarily crash just because an error is thrown in some obscure part of your codebase, the error level of logging ties nicely into this feature and allows the program to continue.

The fatal error level however (`Log.fatal("Message")`) also kills the program after you resume from the error. This is useful for situations where you know there is no way you can handle the error that is generated. This practise of deliberately killing an application is by some considered poor programming practise, however some argue that it's better that you have control and can tell the user exactly what went wrong instead of mystical weird behaviours starts arising further down the line that is more difficult to debug and also more frustrating for the user. An example would be that the user has corrupt files and the message clearly states that there are missing resources and that the user should reinstall or repair the installation before the program is allowed to run, instead of letting the user get 30 minutes into the experience and then having a crash without a comprehensible message, that may even happen without the application getting the chance to save it's state. (Saving the state on fatal error can be achieved with Log through configuring the `LogStream.DEFAULT_CRASH_BEHAVIOR` (see Settings)).

## Creating your own Log stream

In bigger projects you may want to have info about where messages are comming from and control the granularity independently by part of the project so you only show a few relevant debug messages among hundreds. This is solved by the concept of different streams. The idea is that you create one per project partition.

```
var file_stream = LogStream.new("IO")
var networking_stream = LogStream.new("Networking")

func do_networking_stuff():
	networking_stream.warn("No internet. Please connect to the internet for this feature to work")

func do_file_stuff():
	file_stream.dbg("Doing file stuff")
```


## Passing additional values.

Just like in the usual `print()` method it is possible to pass values into Log. this is done through appending a second parameter to the log methods. For example:
`Log.info("Number five looks like this: ", 5)`
Shows the following(in addition to the time, level and stream name):
`Number five looks like this: 5`

This works with basically all types, including Objects, arrays and dictionaries. Since GDScript can't pass extra arguments in a comma separated manner like you do in `print()`, e.g: `print("printing some numbers: ", 1, 2, 3, 4)`, this is done through wrapping the values in an array: `Log.info("printing some numbers: ", [1, 2, 3, 4])` 
## Conditional errors

Log adds the feature of conditional error messages. This feature is almost identical to the internal C++ macros with the same name in the Godot codebase. The idea is basically that they throw an error if a certain condition is met. This is mainly a cosmetic feature to make error checks less cluttery and in that way clean up the code.

All these methods are structured the same way, the first parameter is the value to be checked whether it fulfil the condition (or two in the case of `err_cond_not_equal`), `err_cond_null` checks whether it is equal to null for example.

The second variable to pass is the error message to be printed if the condition is fulfilled.

Thirdly you may pass a bool that indicates whether the error is considered fatal. This is true by default.

Lastly you may pass extra values in the usual way (see 'Passing additional values' part of this document).
### err_cond_null

The method `LogStream.err_cond_null` prints an error to the console if the passed variable is equal to null(which it will in this case since all variables that are not initialized with a value equate to null until their value is set). E.g.: 
```
var null_var
Log.err_cond_null(null_var, "null_var is null, this is forbidden")
```

## err_cond_not_ok

The method `LogStream.err_cond_not_ok` prints an error to the console if the passed variable (Which has to be of type [Error](https://docs.godotengine.org/en/stable/classes/class_%40globalscope.html#enum-globalscope-error)) is not equal to `Error.OK`, or just `OK` for short. E.g.:

```
var path = "invalid file path"
var file = FileAccess.open(path)
Log.err_cond_not_ok(FileAccess.get_open_error(), "Unable to open file", true, path)
```
will print the following:
`Unable to open file. Error string: File not found`

## err_cond_false

The method `LogStream.err_cond_false` prints an error to the console if the passed variable is equal to `false`

## err_cond_not_equal

The method `LogStream.err_cond_not_equal` prints an error to the console if the two passed variables are not equal to each other. follows the same rules as the `==` operator, aka a node that is duplicated is not equal to the original since they are two separate instances, but two strings containing the same characters in the same order are considered equal since GDScript handles them that way. 

# Plugin settings

## Filtering messages

The General idea is that you may want to filter messages based on relevance since logs of a big project can become pretty cluttered with info that isn't relevant to you at the moment or to the end user. What you can do is to set Log up so that for example only errors & Fatals are printed. You do this through setting the LogLevel of the relevant stream. The idea is that messages can be ranked by importance in the order Fatal>error>warning>info>debug. Setting the level to Info means that only messages with an importance Info or higher will show up in the log. Streams, including the main one are set to info by default. Therefore debug messages won't show up by default.

```
func do_something():
	Log.debug("This message will not show in the log")
 	Log.current_log_level = Log.LogLevel.DEBUG
  	Log.debug("However this message will")
```

## Formatting log messages

The constant `LogStream.LOG_MESSAGE_FORMAT` controls how the log messages are formatted in the console, to see specific documentation about formatting in general in GDScript, see the godot string formating documentation [here](https://docs.godotengine.org/en/stable/classes/class_string.html#class-string-method-format). 

By default it looks like:
`{log_name}/{level} [lb]{hour}:{minute}:{second}[rb] {message}`

This means that the following code (called at 12h 34:56 the 8:th of September 2023):
```
var stream = LogStream.new("my stream", LogLevel.DEBUG)
stream.debug("my message")
```
Would look like this:
`my stream/DEBUG [12:34:56] my message` in the console.

Any combination of valid keys and plain text (including some BBCodes) can be combined to create messages with the following exceptions:

- '\[' and ']' which instead are denoted \[lb] for left bracket and \[rb] for rightbracket.
- '{' and '}' cannot be used at all since they are used for the string formatting.

### Valid formatting keys are:
#### {message}
Contains the message you send in to the method. aka "message" in the following code:
`Log.debug("message")`
#### {log_name}
Is the name of the log stream:
```
var stream = LogStream.new("My log")
stream.debug("my message")
```

#### {level}
Is the log level for the current message. This contains one of the values from the section Levels. 

#### Time keys
Inserts different time that the message is logged at in the format used in the const "LOG_TIME_FORMAT". This in turn takes keys that fit in the [Time — Godot Engine (stable)](https://docs.godotengine.org/en/stable/classes/class_time.html#class-time-method-get-datetime-dict-from-system), 

#### BBCodes

BBCodes are a way to graphically formatting text, for example making the time stamp italic. This would be made through this setting the LOG_MESSAGE_FORMAT to `{log_name}/{level} [lb][i]{hour}:{minute}:{second}[/i][rb] {message}`
would print the following:
`my stream/DEBUG [` *`12:34:56`* `] my message`

However only a subset of BBCodes are supported, which all are listed [here](https://docs.godotengine.org/en/stable/classes/class_@globalscope.html#class-globalscope-method-print-rich).

>Note
>debug & warnings have colours hardcoded into the LogStream.\_internal_log() under the match statement. 



## Time format
Log uses the local system time by default. This means that the log will match the time seen in the OS or shown by your phone. If setting `LogStream.USE_UTC_TIME_FORMAT` to true, the log will instead show the UTC time.

## Execution pause on error
The constant `LogStream.BREAK_ON_ERROR` controls whether the plugin breaks the execution of your program when an error (or fatal error) message is logged, and brings up the Editor debugger to show you the error.
>[!Note]
>Since Godot does not let you interact directly with the debugger (to my knowledge), the plugin can't control which stack frame the debugger shows. This means that the error always shows as being caused by the `LogStream._internal_log()` method. This is generally not the case. Instead the error is caused by the code 2 stack frames down. See the image below
>![Pasted image 20231126011500](https://github.com/albinaask/Log/assets/11806563/90938f13-a65c-47fd-b714-6e9350a6a542)
>The actual error is caused in stack frame 2 in the ready function.

## Custom crash behaviours

The setting `LogStream.DEFAULT_CRASH_BEHAVIOR` is a Callable that is called whenever a fatal error is encountered and the program is about to crash. This can be configured to for example restart the program or save the program state. By default it just calls `OS.crash()`. The Godot documentation discourages from using that method and suggests using `get_tree().quit()` instead, according to the author which I personally discussed this matter with this is for the reason described in the 'Levels' section in this document. The difference is that `get_tree().quit()` finishes the current frame and then finishes program execution, which would cause execution to continue past it, which may or may not be desired. Note that any actions to save or restart must be undertaken before the `OS.crash()` is called.
> [!Note]
> At the time of writing a fatal error message isn't shown in the editor console(may also include messages that shortly precedes the fatal error) due to a [Bug in godot](https://github.com/godotengine/godot/issues/85072#issuecomment-1818220719). 

# Legacy code
There is some legacy code present that is still from the original repo which seem to work, but is undocumented and that I'm not really sure what it does, but make of that what you will...

## JsonData
### Methods
- marshal(obj:Object,compact:bool=false,compressMode:int=-1,skip_whitelist:bool=false) -> PackedByteArray:

- unmarshal(dict:Dictionary,obj:Object,compressMode:int=-1) -> bool:

- unmarshal_bytes_to_dict(data:PackedByteArray,compressMode:int=-1) -> Dictionary:

- unmarshal_bytes(data:PackedByteArray,obj:Object,compressMode:int=-1) -> bool:

- to_dict(obj:Object,compact:bool,skip_whitelist:bool=false) ->Dictionary:

## Config
Will get either flags or env vars for the program and return the value or the default value.
### Methods

- get_var(name,default=""):

- get_int(name,default=0) -> int:
	
- get_bool(name,default=false,prefix:String="") -> bool:

- get_custom_var(name,type,default=null):
