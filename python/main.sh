#!/bin/env sh

case "$1" in
    (unittest)
        echo "> python3 -m unittest discover -v -s python"
        python3 -m unittest discover -v -s python
        ;;
    (*)
        echo "> python3 -m python.main"
        python3 -m python.main
        ;;
esac
