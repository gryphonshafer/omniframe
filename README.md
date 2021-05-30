# Omniframe

[![test](https://github.com/gryphonshafer/omniframe/workflows/test/badge.svg)](https://github.com/gryphonshafer/omniframe/actions?query=workflow%3Atest)
[![codecov](https://codecov.io/gh/gryphonshafer/omniframe/graph/badge.svg)](https://codecov.io/gh/gryphonshafer/omniframe)

This is a multi-purpose base framework for projects. It's intended to be used
in parallel with projects that depend upon it. By itself, it does little. The
point of this project is to deduplicate frequently duplicated components between
a set of projects.

## Installation

To install the framework, you will need to ensure the following prerequisites
are available:

- SQLite (3.21 minimum version required; newest stable version recommended)
- Perl (5.22 minimum version required; newest stable version recommended)
- CPANminus (`cpanm`)

### Development or Build Environments

For a development or build environment, you will likely also want:

- Dart Sass (`sass`)

*(If you don't install Dart Sass, the build of sass code will be silently
skipped.)*

### Project Clone and Module Dependencies

Clone this project to a desired location. Then perform the following from
within this project's root directory:

    cpanm -n -f --installdeps .

## Project Setup

To setup an application (existing or new), use one the following instructions:

### New Dependent Project

To setup a new project that depends on this project, change to the desired
location for the new project. This is recommended to be in a parallel directory
to this project's root directory, though this is not required. Then (assuming
you are in a directory which is parallel to this project's root named
`omniframe`) run:

    ../omniframe/tools/build_app.pl --man

Then follow the instructions.

### Existing Dependent Project

Clone the existing dependent project to the desired location. This is
recommended to be in a parallel directory to this project's root directory,
though this is not required. Then edit the `~/config/app.yaml` file relative to
the dependent project's root. If you change where the relative location of the
dependent project's root from this project's root, you will need to change the
paths to `libs`, `omniframe`, and `preinclude` along with any other pointers
to this projects resources.

### External Resources

Depending on the dependent project, it may be necessary to install external
resources into the Omniframe  installation. From within your dependent project's
root directory (and assuming the dependent project's root is a directory which
is parallel to the Omniframe project's root named `omniframe`) run:

    ../omniframe/tools/install_externals.pl --man

Then follow the instructions.

## Run Application

To run the dependent project application, follow the instructions in the
`~/app.psgi` file within the dependent project's root directory.
