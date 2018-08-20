#! /bin/bash

if [ "$MSSPI" = "yes" ]; then
    sudo linux-amd64_deb/install.sh $CSPMODE
    cd src/msspi/build_linux && 
    make &&
    cd ../../.. ;
fi

autoreconf -fvi && touch src/dhparam.c

./configure $CONFIGURE_OPTIONS

make

if [ -z "$MSSPI" ]; then 
    make test || ( for FILE in tests/logs/*.log; do echo "*** $FILE ***"; cat "$FILE"; done; false ); 
else
    if [ "$MSSPI" = "yes" ]; then 
        mv ./src/stunnel ./src/stunnel-msspi && 
        cd tests && 
        sudo perl test-stunnel-msspi.pl && 
        cd ../src && 
        tar -cvzf ${TRAVIS_TAG}_linux-amd64_deb.tar.gz stunnel-msspi &&
        cd ..; 
    fi
fi