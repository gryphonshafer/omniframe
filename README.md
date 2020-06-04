# Omniframe

This is a multi-purpose base framework for projects. It's intended to be used
in parallel with projects that depend upon it. By itself, it does little. The
point of this project is to deduplicate frequently duplicated components between
a set of projects.

## Setup

To setup an application (existing or new) in a fresh environment, you will need
to ensure the following prerequisites are installed:

- Perl
- CPANminus (`cpanm`)
- SQLite
- `libsass`

Clone this project to a desired location. Then perform the following from
within this project's root directory:

    cpanm -n -f --installdeps .

### New Dependent Project

To setup a new project that depends on this project, change to the desired
location for the new project. This is recommended to be in a parallel directory
to this project's root directory, though this is not required. Then (assuming
you are in a directory which is parallel to this project's root named
`omniframe`) run:

    ../omniframe/tools/build.pl --man

Then follow the instructions.

### Existing Dependent Project

Clone the existing dependent project to the desired location. This is
recommended to be in a parallel directory to this project's root directory,
though this is not required. Then edit the `~/config/app.yaml` file relative to
the dependent project's root. If you change where the relative location of the
dependent project's root from this project's root, you will need to change the
paths to `libs`, `omniframe`, and `preinclude` along with any other pointers
to this projects resources.

## Run

To run the dependent project application, follow the instructions in the
`~/app.psgi` file within the dependent project's root directory.
