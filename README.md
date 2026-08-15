[![Gem Version](https://badge.fury.io/rb/rggen-systemrdl.svg)](https://badge.fury.io/rb/rggen-systemrdl)
[![CI](https://github.com/rggen/rggen-systemrdl/actions/workflows/ci.yml/badge.svg)](https://github.com/rggen/rggen-systemrdl/actions/workflows/ci.yml)
[![Discord](https://img.shields.io/discord/1406572699467124806?style=flat&logo=discord)](https://discord.com/invite/KWya83ZZxr)

# RgGen::SystemRDL

RgGen::SystemRDL is a RgGen plugin to load register map descriptions written in [SystemRDL 2.0](https://www.accellera.org/images/downloads/standards/systemrdl/SystemRDL_2.0_Jan2018.pdf).

## Installation

To install RgGen::SystemRDL, use the following command:

```
$ gem install rggen-systemrdl
```

## Usage

You need to tell RgGen to load the RgGen::SystemRDL plugin. There are two ways.

### Using the `--plugin` runtime option

```
$ rggen --plugin rggen-systemrdl your_register_map.rdl
```

### Using the `RGGEN_PLUGINS` environment variable

```
$ export RGGEN_PLUGINS=${RGGEN_PLUGINS}:rggen-systemrdl
$ rggen your_register_map.rdl
```

## Supported features and limitations

The plugin converts SystemRDL `addrmap`, `regfile`, `reg`, `field`, and `mem` components into the corresponding RgGen register map layers, including a wide range of `field` access types.
Some SystemRDL constructs have no corresponding concept in RgGen. These are not supported and cause an error.

For the detailed component-to-layer correspondence, the full SystemRDL-property to RgGen-type mapping, and the complete list of unsupported constructs with the reasons behind each decision, see the design notes:

* [SystemRDL to RgGen mapping](notes/systemrdl_to_rggen_mapping.md)
* [Bit field type matrix](notes/bit_field_type_matrix.md)

### Precedence handling

RgGen fixes precedence to hardware, whereas SystemRDL's precedence is variable and defaults to software.
A field is therefore rejected unless its precedence is explicitly set to `hw`.

To accept a SystemRDL description without changing it, set the `ignore_precedence` configuration option (default `false`) to `true`.
Then the `precedence` property in the SystemRDL description is ignored and every field is treated as hardware precedence.

## Contact

Feedbacks, bug reports, questions and etc. are welcome! You can post them by using the following
ways:

* [GitHub Issue Tracker](https://github.com/rggen/rggen/issues)
* [GitHub Discussions](https://github.com/rggen/rggen/discussions)
* [Discord](https://discord.com/invite/KWya83ZZxr)
* [Mailing List](https://groups.google.com/d/forum/rggen)
* [Mail](mailto:rggen@googlegroups.com)

## Copyright & License

Copyright &copy; 2026 Taichi Ishitani.
RgGen::SystemRDL is licensed under the [MIT License](https://opensource.org/licenses/MIT), see [LICENSE](LICENSE) for further details.
