# RetroPie Create New System

A tool for RetroPie to create new systems for EmulationStation.

## Installation

```
cd /home/pi/
git clone https://github.com/hiulit/RetroPie-Create-New-System
cd RetroPie-Create-New-System
sudo chmod +x retropie-create-new-system.sh
```

## Usage

```
./retropie-create-new-system.sh [OPTIONS] 
```

If no options are passed, you will be prompted with a usage example:

```
USAGE: ./retropie-create-new-system.sh [OPTIONS]

Use '--help' to see all the options.
```

## Options


* `--help`: Print the help message and exit.
* `--version`: Show script version.

## Examples

### `--help`

Print the help message and exit.

#### Example


`./retropie-create-new-system.sh --help`

### `--version`

Show script version.

#### Example

`./retropie-create-new-system.sh --version`


## Config file

[CONFIG_FILE_DESCRIPTION]

**COMMENTS:**
- **Copy and paste your config file.**
- **If the config file is too big, maybe it's not a good idea to add it here.**
- **Remember to remove these comments.**

```
# Settings for [SCRIPT_TITLE] (e.g. RetroPie Shell Script Boilerplate)

# Add your own [key = "value"] (e.g. path_to_whatever = "/path/to/whatever")
# [KEY] WITHOUT quotes.
# [VALUE] WITH quotes.
# There MUST be 1 space before and after '='.
# To indicate that a [KEY] has NO [VALUE] or is NOT SET, just leave the quotes, like this: "".

# Description of the [key = "value"] (e.g. # Set path to whatever).
[KEY] = "[VALUE]"

# Add your own [key = "value"]
```

## Changelog

See [CHANGELOG](/CHANGELOG.md).

## Contributing

See [CONTRIBUTING](/CONTRIBUTING.md).

## Authors

* Me 😛 [@hiulit](https://github.com/hiulit).

## Credits

Thanks to:
 
* All the people at the [RetroPie Forum](https://retropie.org.uk/forum/).

## License

[MIT License](/LICENSE).
