# Installation, Setup, and Execution

## Installation

To install the framework, you will need to ensure the following prerequisites
are available:

- SQLite (3.21 minimum version required; newest stable version recommended)
- Perl (5.22 minimum version required; newest stable version recommended)
- CPANminus (`cpanm`)

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

If the dependent project includes a `cpanfile` in its root directory, you will
need to (from the project's root directory) run the following:

    cpanm -n -f --installdeps .

### External Resources

Depending on the dependent project, it may be necessary to install external
resources into the Omniframe installation. From within your dependent project's
root directory (and assuming the dependent project's root is a directory which
is parallel to the Omniframe project's root named `omniframe`) run:

    ../omniframe/tools/install_externals.pl --man

Then follow the instructions.

## Application Execution

To run the dependent project application, follow the instructions in the
`~/app.psgi` file within the dependent project's root directory.
