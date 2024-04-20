#!/usr/bin/bash

if [ "$#" -eq 0 ]; then
    echo "Must provide a target";
    exit -1;
fi

TARGET="$1";
SAMPLE_DIR="./data/$TARGET";

if ! [ -d $SAMPLE_DIR ]; then
    URL="https://open.kattis.com/problems/$1/file/statement/samples.zip";

    if ! curl --connect-timeout 1 -o /dev/null -sfIL $URL 2>&1; then
        echo "Could not verify sample file at $URL";
        exit -1;
    fi

    mkdir -p $SAMPLE_DIR;
    curl -sL $URL -o samples.zip;
    unzip samples.zip -d $SAMPLE_DIR;
    rm samples.zip;
fi

ZIG_OUT="./zig-out"
mkdir -p $ZIG_OUT;

KATTIS_OUT="$ZIG_OUT/$TARGET";
MAIN_FILE="./src/$1.zig";

cp "./src/main.zig" $MAIN_FILE;

zig build-exe -O ReleaseFast -femit-bin="$KATTIS_OUT" $MAIN_FILE;

if [ $? -ne 0 ]; then
    echo "Build failed."
    exit -1;
fi

clear;

for file in $SAMPLE_DIR/*.in; do
    EXAMPLE=$(basename "$file" .in)
    echo "BEGIN $EXAMPLE"

    cat $file | $KATTIS_OUT;
    
    echo "EXPECTED"

    cat "$SAMPLE_DIR/$EXAMPLE.ans"

    echo "END"
    echo "";
done

