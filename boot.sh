#!/bin/bash
echo "boot: starting page server" &&\
./client/node_modules/coffee-script/bin/coffee ./client/static_server.coffee \
&\
echo "boot: starting mouse server" &&\
/usr/bin/python mousesocket.py
