#!/bin/bash
# Based on a test script from avsm/ocaml repo https://github.com/avsm/ocaml

CHROOT_DIR=/tmp/armv7-chroot
MIRROR=http://archive.raspbian.org/raspbian
VERSION=jessie
CHROOT_ARCH=armhf
ARCH=arm
#TRAVIS_BUILD_DIR=/home/full/Desktop/git-full/ANOTHER_GIT/stunnel

# Debian package dependencies for the host
HOST_DEPENDENCIES="debootstrap qemu-user-static binfmt-support sbuild"

# Debian package dependencies for the chrooted environment
# TODO: Fix lsb-core lsb-core-noarch (when someone fix CSP)
GUEST_DEPENDENCIES="build-essential git m4 autoconf libtool sudo python lsb-core lsb-core-noarch"

# Command used to run the tests
TEST_COMMAND="make test"

#sudo mkdir /tmp/armv7-chroot

#sudo debootstrap --foreign --no-check-gpg --include=fakeroot,build-essential,autoconf-archive,libssl-dev,libwrap0-dev --arch=armhf jessie /tmp/armv7-chroot http://archive.raspbian.org/raspbian

#sudo cp /usr/bin/qemu-arm-static /tmp/armv7-chroot/usr/bin/

#sudo chroot /tmp/armv7-chroot ./debootstrap/debootstrap --second-stage

#sudo sbuild-createchroot --arch=armhf --foreign --setup-only jessie /tmp/armv7-chroot http://archive.raspbian.org/raspbian

#sudo chroot /tmp/armv7-chroot apt-get update

#sudo chroot /tmp/armv7-chroot apt-get --allow-unauthenticated install -qq -y build-essential git m4 autoconf libtool sudo python

#sudo mkdir -p /tmp/armv7-chroot/home/full/Desktop/git-full/ANOTHER_GIT/stunnel

#sudo rsync -av /home/full/Desktop/git-full/ANOTHER_GIT/stunnel/ /tmp/armv7-chroot/home/full/Desktop/git-full/ANOTHER_GIT/stunnel

if [ ! -e "/.chroot_is_done" ]; then
    #-----------------------------------------------------------------------------
    echo "Prepare chroot environment"

    sudo apt-get install -qq -y ${HOST_DEPENDENCIES}

    # Create chrooted environment
    sudo mkdir ${CHROOT_DIR}
    sudo debootstrap --foreign --no-check-gpg --include=fakeroot,build-essential,autoconf-archive,libssl-dev,libwrap0-dev \
        --arch=${CHROOT_ARCH} ${VERSION} ${CHROOT_DIR} ${MIRROR}
    sudo cp /usr/bin/qemu-arm-static ${CHROOT_DIR}/usr/bin/
    sudo chroot ${CHROOT_DIR} ./debootstrap/debootstrap --second-stage
    sudo sbuild-createchroot --arch=${CHROOT_ARCH} --foreign --setup-only \
        ${VERSION} ${CHROOT_DIR} ${MIRROR}

    # Force delete foreign amd64 (TODO: why is not it removed by sbuild?).
    # Need for apt-get update from binary-armhf instead binary-amd64.
    sudo chroot ${CHROOT_DIR} dpkg --remove-architecture amd64
    
    # Create file with environment variables which will be used inside chrooted
    # environment
    echo "export TRAVIS_BUILD_DIR=\'${TRAVIS_BUILD_DIR}\'" > envvars.sh
    echo "export ARCH=\'${ARCH}\'" >> envvars.sh
    echo "export CONFIGURE_OPTIONS=\'${CONFIGURE_OPTIONS}\'" >> envvars.sh
    echo "export MSSPI=\'${MSSPI}\'" >> envvars.sh
    echo "export CSPMODE=\'${CSPMODE}\'" >> envvars.sh
    echo "export TRAVIS_TAG=\'${TRAVIS_TAG}\'" >> envvars.sh
    echo "export CPRO_SUFFIX=\'arm\'" >> envvars.sh
    chmod a+x envvars.sh

    # Install dependencies inside chroot (g++-4.9 already exist)
    sudo chroot ${CHROOT_DIR} apt-get update
    sudo chroot ${CHROOT_DIR} apt-get --allow-unauthenticated install \
        -qq -y ${GUEST_DEPENDENCIES}

    # Create build dir and copy travis build files to our chroot environment
    sudo mkdir -p ${CHROOT_DIR}${TRAVIS_BUILD_DIR}
    sudo rsync -av ${TRAVIS_BUILD_DIR}/ ${CHROOT_DIR}${TRAVIS_BUILD_DIR}/

    # Indicate chroot environment has been set up
    sudo touch ${CHROOT_DIR}/.chroot_is_done

    # Call ourselves again which will cause tests to run
    sudo chroot ${CHROOT_DIR} bash -cex "cd ${TRAVIS_BUILD_DIR} && ./build_armv7.sh"
    #-----------------------------------------------------------------------------
else
    # We are inside ARM chroot
    echo "Running inside chrooted environment"

    . ./envvars.sh

    if [ "$MSSPI" = "yes" ]; then
        sudo linux-armhf_deb/install.sh $CSPMODE
        cd src/msspi/build_linux && 
        make &&
        cd ../../.. ;
    fi

    autoreconf -fvi && touch src/dhparam.c

    ./configure $CONFIGURE_OPTIONS

    # TODO: Delete it MEGA CRUTCH!!!!(!?!?!?!?!?)
    cp /opt/cprocsp/lib/arm/libcapi10*4.0.4* ./src/msspi/build_linux/libcapi10.so
    cp /opt/cprocsp/lib/arm/libcapi20*4.0.4* ./src/msspi/build_linux/libcapi20.so

    make

    if [ -z "$MSSPI" ]; then
        make test || ( for FILE in tests/logs/*.log; do echo "*** $FILE ***"; cat "$FILE"; done; false );
    else
        if [ "$MSSPI" = "yes" ]; then
            mv ./src/stunnel ./src/stunnel-msspi &&
            cd tests &&
            sudo perl test-stunnel-msspi.pl &&
            cd ../src &&
            tar -cvzf ${TRAVIS_TAG}_linux-armhf_deb.tar.gz stunnel-msspi &&
            cd ..;
        fi
    fi

    exit 0
fi

mv ${CHROOT_DIR}${TRAVIS_BUILD_DIR}/src/${TRAVIS_TAG}_linux-armhf_deb.tar.gz ./src/
