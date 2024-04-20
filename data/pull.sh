#!/usr/bin/bash

if [ "$#" -eq 0 ]; then
    echo "Must provide a target url";
    exit -1;
fi

OUT_DIR=".";
URL="$1";

if curl --connect-timeout 1 -o /dev/null -sfIL $URL 2>&1; then
    echo "URL exists"
else
    URL="https://open.kattis.com/problems/$1/file/statement/samples.zip";

    if curl --connect-timeout 1 -o /dev/null -sfIL $URL 2>&1; then
        echo "Resolved to URL: $URL";
        while true; do
            read -p "Is this correct? (y/n) " yn;
            case $yn in
                [Yy]* ) break;;
                [Nn]* ) exit;;
            esac
        done

        OUT_DIR="./$1";
        rm -r $OUT_DIR
        mkdir $OUT_DIR;
    else
        echo "URL does not exist"
        exit -1;
    fi
fi

TARGET="$OUT_DIR/sample.zip"

curl -sL $URL -o $TARGET;

# Remove old files;
rm $OUT_DIR/*.in;
rm $OUT_DIR/*.ans;

unzip $TARGET -d $OUT_DIR;
rm $TARGET;
