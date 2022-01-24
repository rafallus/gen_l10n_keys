# Automatic Localization key generation

The script can be used to scan a Godot project, look for possible localization keys and generate a .csv file with the keys found. The script can get translation strings from GDScript (\*.gd) and PackedScene files (\*.tscn, \*.scn).

## How to use

Copy the script into your project (the location is not important). Open the script in the Godot Script Editor. In the Script Editor menu go to File > Run.

## GDScript files

Strings used as argument in the `tr()` function are considered as translatable strings. The following examples show in which cases the string is a valid localization key.
```gdscript
label.text = tr("Some string")            # Valid
label.text = my_object.tr("Other string")  # Valid
label.text = "1. "+tr("Point one string") # Valid
label.text = str("A different string")    # Not included as key
my_func(arg1, tr("My string"))            # Valid
my_func(arg2,tr("My other string"))       # Valid
my_func(arg3, tr(string_var))             # Not included as key
```

## Scene files

Some `Control` nodes have properties for which localization is desirable. These properties are the following:
- `text`: used by `Button`, `Label`, `LineEdit`, `RichTextLabel` and `TextEdit`.
- `hint_tooltip`: used by all `Control` nodes.
- `placeholder_text`: used by `LineEdit`.
- `bbcode_text`: used by `RichTextLabel`.
- `dialog_text`: used by `AcceptDialog`.
- `window_title`: used by `WindowDialog`.
- Text in `ItemList`, `PopupMenu` and `OptionButton` items.
- `TabContainer` children names.

# Excluding nodes

To exclude a node from being translated, it must be added to a group called **notranslation**.

# Options

At the top of the script, there are some constants that can be used to customize the CSV file generation.
- **TR_FILE_PATH**: the path to the translation \*.csv file. If a file with the same name is found, translations already present in the file are preserved.
- **CSV_DELIM**: delimiter character used in the CSV file.
- **CLEAN_NOT_FOUND_KEYS**: if `true`, keys present in the existing CSV file that are not found in the project will be ignored and the newly generated CSV file won't contain those keys.
- **SKIP_DIRS**: a list of directories to skip during the scanning.
- **NUM_BACKUP_FILES**: maximum number of backup files generated.

# Compatibility

The script has been tested with Godot version 3.4.2, but should also work with previous versions.
