#!/bin/bash

# generate a file to simulate user input during config (default mem, disable chromium, rw)
printf '1\n3\n1\n' > user_conf
# run setup script
source sources/meta-bsp-imx8mq/tools/setup-imx8mq-env -b build-${MACHINE}-${DISTRO} < user_conf
 # override sanity check url,
 echo 'CONNECTIVITY_CHECK_URIS = "https://www.orf.at"' >> conf/local.conf
 # enable virtualization distro feature
 echo 'DISTRO_FEATURES_append = " virtualization"' >> conf/local.conf
 # fix missing config for bitbake-layers (must near top of config file)
 sed -i '1iBBINCLUDELOGS = "yes"' conf/local.conf
 # add meta-virtualization layer
 bitbake-layers add-layer ../sources/meta-virtualization
 # add docker to build
 echo 'CORE_IMAGE_EXTRA_INSTALL += "docker"' >> conf/local.conf
 # add mdns to build
 echo 'CORE_IMAGE_EXTRA_INSTALL += "mdns"' >> conf/local.conf
 # added ifupdown to build
 echo 'CORE_IMAGE_EXTRA_INSTALL += "connman"' >> conf/local.conf
 # Run image create
 bitbake -k ${IMAGE}