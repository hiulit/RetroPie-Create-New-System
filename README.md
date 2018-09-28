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
sudo ./retropie-create-new-system.sh [OPTIONS] 
```

If no options are passed, you will be prompted with a usage example:

```
USAGE: sudo ./retropie-create-new-system.sh [OPTIONS]

Use '--help' to see all the options.
```

## Options

* `--help`: Print the help message and exit.
* `--gui`: Start the GUI.
* `--version`: Show script version.

## Examples

### `--help`

Print the help message and exit.

#### Example


`sudo ./retropie-create-new-system.sh --help`

### `--gui`

Start the GUI.

#### Example

`sudo ./retropie-create-new-system.sh --gui`

### `--version`

Show script version.

#### Example

`sudo ./retropie-create-new-system.sh --version`

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
