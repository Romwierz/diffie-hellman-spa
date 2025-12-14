#!/bin/env sh

case "$1" in
    (unittest)
        echo "> python3 -m unittest"
        python3 -m unittest -v
        ;;
    (*)
        echo "> python3 -m python.main"
        python3 -m python.main
        ;;
esac
