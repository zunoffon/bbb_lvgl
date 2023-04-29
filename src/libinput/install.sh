#!/bin/bash
SCRIPT_DIR="$(dirname -- "$0")"
pushd $SCRIPT_DIR
PKGS=$(apt-cache -o=APT::Architecture="armhf" depends --recurse --no-recommends --no-suggests --no-conflicts --no-breaks --no-replaces --no-enhances --no-pre-depends libinput-dev | grep '^\w')
for pkg in $PKGS
do
	if ls $pkg* 1> /dev/null 2>&1; then
		echo "Package [$pkg] exist, skip download."
	else
		echo "Downloading [$pkg] ..."
		apt-get -o=APT::Architecture="armhf" download $pkg
	fi
done

rm -r */ 2>/dev/null

for f in *.deb 
do
	echo "Extracting [$f] ..."
	dpkg-deb -x $f .
done
popd
