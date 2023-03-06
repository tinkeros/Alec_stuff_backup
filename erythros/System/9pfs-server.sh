#!/bin/sh
while true; do socat TCP4-LISTEN:5640,reuseaddr,fork EXEC:"u9fs -a none -u $USER `eval echo ~$USER`/9p/root"; done
