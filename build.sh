#! /bin/bash

# create a temporary directory
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMP_DIR=$(mktemp -d -p $DIR)

if [[ ! $TMP_DIR || ! -d $TMP_DIR ]]; then
    echo "Error creating temp dir"
    exit 1
fi

echo "Created dir $TMP_DIR"
function cleanup {
    rm -rf $TMP_DIR
    echo "Deleted dir $TMP_DIR"
}

# make sure to delete the temporary directory
trap cleanup EXIT

# copy packages over to the temporary directory
cp "${DIR}/packages" $TMP_DIR -r

# build every packages
for package in ${TMP_DIR}/packages/*; do
    cd $package || continue && makepkg
done

# copy artifacts to the builds directory without overwriting
for file in ${TMP_DIR}/packages/**/*.pkg.tar.zst; do
    cp $file "$DIR/builds" -n
done

# create database and remove sym links
cd "${DIR}/builds" || exit &&
    repo-add tiagovla.db.tar.gz *.pkg.tar.zst &&
    rm *.db *.files

# remove extensions
for f in ${DIR}/builds/*.tar.gz; do
    if [ -f $f ]; then
        mv $f ${f%.tar.gz} || continue
    fi
done
