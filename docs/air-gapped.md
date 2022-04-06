# Air-gapped installation

`docker-setup` downloads several file during the installation. Some of them are coming from this repository. These files can now be placed in `/var/lib/docker-setup/contrib` to reduce the dependency on an internet connection. A tarball is published in the release (`contrib.tar.gz`) and included in the container image.

Air-gapped installations are not possible because not all files are included in the contrib tarball.