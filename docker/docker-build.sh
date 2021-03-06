#!/bin/bash

set -euo pipefail
basedir=$(pwd)

cp ./smoove /usr/local/bin
chmod +x /usr/local/bin/smoove

# used by Dockerfile
apt-get update
apt-get -qy install \
    zlib1g-dev \
    make build-essential cmake libncurses-dev ncurses-dev g++ gcc \
    python python-dev python-pip nfs-common \
    pigz bedtools gawk curl fuse wget git mdadm time \
    libbz2-dev lzma-dev liblzma-dev \
    syslog-ng libssl-dev libtool autoconf automake \
    libcurl4-openssl-dev libffi-dev libblas-dev liblapack-dev libatlas-base-dev

git clone --depth 1 https://github.com/ebiggers/libdeflate.git 
cd libdeflate
make -j 2 CFLAGS='-fPIC -O3' libdeflate.a
cp libdeflate.a /usr/local/lib
cp libdeflate.h /usr/local/include
cd $basedir
rm -rf libdeflate

git clone --recursive https://github.com/samtools/htslib.git
git clone --recursive https://github.com/samtools/samtools.git
git clone --recursive https://github.com/samtools/bcftools.git
cd htslib && git checkout 5a062a4 && autoheader && autoconf && ./configure --enable-libcurl --with-libdeflate
cd .. && make -j4 CFLAGS="-fPIC -O3" -C htslib install
cd $basedir

cd bcftools #&& git checkout 1.7
autoreconf && ./configure
set +e
make bcftools "PLUGINS_ENABLED=no" #
#"CFLAGS=-g -Wall -O2 -pedantic -std=c99 -D_XOPEN_SOURCE=600"
set -e
cp ./bcftools /usr/local/bin
cd $basedir
rm -rf bcftools

cd samtools && git checkout 1.8
autoreconf && ./configure && make -j2 CFLAGS='-fPIC -O3' install
cd $basedir && cp ./samtools/samtools /usr/local/bin/

wget -qO /usr/bin/batchit https://github.com/base2genomics/batchit/releases/download/v0.4.2/batchit
chmod +x /usr/bin/batchit

pip install -U awscli cython slurmpy toolshed awscli-cwlogs pyvcf pyfaidx cyvcf2 pip svtools

cd $basedir
git clone https://github.com/hall-lab/svtyper
cd svtyper && python setup.py install
cd $basedir
rm -rf svtyper


wget -qO /usr/local/bin/mosdepth https://github.com/brentp/mosdepth/releases/download/v0.2.1/mosdepth
chmod +x /usr/local/bin/mosdepth
wget -qO /usr/bin/gsort https://github.com/brentp/gsort/releases/download/v0.0.6/gsort_linux_amd64
chmod +x /usr/bin/gsort

wget -qO /usr/bin/gargs https://github.com/brentp/gargs/releases/download/v0.3.9/gargs_linux
chmod +x /usr/bin/gargs

git clone --single-branch --recursive --depth 1 https://github.com/arq5x/lumpy-sv
cd lumpy-sv
make -j 3
cp ./bin/* /usr/local/bin/

cd $basedir

rm -rf lumpy-sv

ldconfig

rm -rf /var/lib/apt/lists/*
