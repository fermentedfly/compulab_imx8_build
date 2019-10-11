# compulab_imx8

Compulab iMX8 build tools

## Usage

Create Docker image
This downloads all dependencies and sources and creates a container ready for build

```bash
docker build --build-arg "host_uid=$(id -u)" --build-arg "host_gid=$(id -g)" --build-arg "CACHEBUST=$(date +%s)" --tag yocto .
```

Create a output folder in the same directory

```bash
mkdir output
```

Run Image to build

```bash
docker run -it --rm -v $PWD/output:/home/vifdaq/vifdaq_v3/build-cl-som-imx8-fsl-imx-xwayland yocto
```

The iMX image can be found in ./output/tmp/deploy/images/cl-som-imx8/core-image-full-cmdline-cl-som-imx8-XXX.rootfs.sdcard.bz2
