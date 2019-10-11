# YOCTO Build Container

# https://github.com/bstubert/cuteradio/blob/master/Dockerfile

# Compulab IMX seems to run on Yocto 2.5 (sumo branch)

# BUILD
# docker build --build-arg "host_uid=$(id -u)" --build-arg "host_gid=$(id -g)" --tag yocto .
#
# RUN
# docker run -it --rm -v $PWD/output:/home/vifdaq/vifdaq_v3/build-cl-som-imx8-fsl-imx-xwayland -e root_password=vifdaq yocto

# Base Image Ubuntu LTS
FROM ubuntu:18.04

# Yocto build dependencies
# curl (google repo)
# locales (setup locale)
RUN apt-get update && apt-get -y install gawk wget git-core diffstat unzip texinfo gcc-multilib \
     build-essential chrpath socat cpio python python3 python3-pip python3-pexpect \
     xz-utils debianutils iputils-ping libsdl1.2-dev xterm curl locales

# fix sh alias
RUN rm /bin/sh && ln -s bash /bin/sh
# change shell to bash during installation
SHELL ["/bin/bash", "-c"]

# Set the locale to en_US.UTF-8, because the Yocto build fails without any locale set.
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

# install vim after locale has been set up
RUN apt-get install -y vim

ENV USER_NAME vifdaq
ENV PROJECT vifdaq_v3


# The running container writes all the build artefacts to a host directory (outside the container).
# The container can only write files to host directories, if it uses the same user ID and
# group ID owning the host directories. The host_uid and group_uid are passed to the docker build
# command with the --build-arg option. By default, they are both 1001. The docker image creates
# a group with host_gid and a user with host_uid and adds the user to the group. The symbolic
# name of the group and user is vifdaq.
ARG host_uid=1001
ARG host_gid=1001
# disable log (useradd breaks at large user ids) https://github.com/moby/moby/issues/5419
RUN groupadd -g $host_gid $USER_NAME && useradd --no-log-init -g $host_gid -m -s /bin/bash -u $host_uid $USER_NAME

# Perform the Yocto build as user vifdaq (not as root).
# NOTE: The USER command does not set the environment variable HOME.

# By default, docker runs as root. However, Yocto builds should not be run as root, but as a 
# normal user. Hence, we switch to the newly created user cuteradio.
USER $USER_NAME

# install google repo
WORKDIR /home/$USER_NAME
RUN mkdir bin
RUN curl https://storage.googleapis.com/git-repo-downloads/repo > bin/repo
RUN chmod a+x bin/repo
ENV PATH="/home/$USER_NAME/bin:${PATH}"

# create the build folder
WORKDIR /home/$USER_NAME
RUN mkdir $PROJECT
WORKDIR $PROJECT

# Copulab Build instructions from here
# https://mediawiki.compulab.com/w/index.php?title=Building_CL-SOM-iMX8_Yocto_Linux_images
RUN repo init -u git://source.codeaurora.org/external/imx/imx-manifest.git -b imx-linux-sumo -m imx-4.14.98-2.0.0_ga.xml
RUN repo sync

RUN git clone -b master https://github.com/compulab-yokneam/meta-bsp-imx8mq.git sources/meta-bsp-imx8mq
RUN git -C sources/meta-bsp-imx8mq checkout master

# virtualization meta repo
RUN git clone -b sumo git://git.yoctoproject.org/meta-virtualization sources/meta-virtualization
RUN git -C sources/meta-virtualization checkout sumo

ENV MACHINE=cl-som-imx8
ENV DISTRO=fsl-imx-xwayland
ENV IMAGE=core-image-full-cmdline

# generate a file to simulate user input during config (default mem, disable chromium, rw)
RUN printf '1\n3\n1\n' > user_conf

# run setup script
CMD source sources/meta-bsp-imx8mq/tools/setup-imx8mq-env -b build-${MACHINE}-${DISTRO} < user_conf && \
 # override sanity check url,
 echo 'CONNECTIVITY_CHECK_URIS = "https://www.orf.at"' >> conf/local.conf && \
 # enable virtualization distro feature
 echo 'DISTRO_FEATURES_append = " virtualization"' >> conf/local.conf && \
 # fix missing config for bitbake-layers (must near top of config file)
 sed -i '1iBBINCLUDELOGS = "yes"' conf/local.conf && \
 # add meta-virtualization layer
 bitbake-layers add-layer ../sources/meta-virtualization && \
 # add docker to build
 echo 'CORE_IMAGE_EXTRA_INSTALL += " docker-ce"' >> conf/local.conf && \
 # add mdns to build
 echo 'CORE_IMAGE_EXTRA_INSTALL += " mdns"' >> conf/local.conf && \
 # added ifupdown to build
 echo 'CORE_IMAGE_EXTRA_INSTALL += " connman"' >> conf/local.conf && \
 # set root password
 echo 'INHERIT += "extrausers"' >> conf/local.conf && \
 echo 'EXTRA_USERS_PARAMS = "usermod -p "'"${root_password}"'" root;"' >> conf/local.conf && \
 # Run image create
 bitbake -k ${IMAGE}
