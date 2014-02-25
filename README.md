## Docker Ruby Build

This repo contains build scripts to create packages for a variety
of ruby installation formats.

The following are currently supported:

- Ubuntu install of rbenv ruby under /usr/local/rbenv
  - Versions: 1.9.3, 2.1.0
- Centos install of rbenv ruby under /usr/local/rbenv
  - Versions: 1.9.3, 2.1.0
- Centos install of rvm ruby under /usr/local/rvm
  - Versions: 1.9.3, 2.1.0

## Building

Each directory contains a build environment for the specific ruby build.
It is required that these build scripts are run on the host running
docker. These cannot be run remotely as the bind mount used to extract
the package will not work.

1) cd to the directory to be built:

`cd rbenv_multi_centos`

2) Run build script:

`sh ./build.sh`

3) If this completes it should create a 'pkg' directory containing the
resulting package:

```
-rw-r--r-- 1 root root 993040 Feb 24 21:34 rbenv-multi-0.0.1-1.x86_64.rpm
```

## Versioning

Currently there are two version files that are relevant:

`build_version.txt` - this file manages the version of the resulting
package from the build process

`versions.txt` - This contains a list of the ruby versions to be built.
Note that these are passed directly into the tool, so the versions must
be in the format expected by rbenv or rvm.
