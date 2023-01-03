#!/bin/bash
#
#  build.sh
#  factorio-rt-light-bot-start
#
#  Created by Rakesh Ayyaswami on 03 Jan 2023.
#

# Read info key path
function read_info() {
  echo $(npm run --silent read-info -- ${1})
}

# Constants
BUILD_DIR=build
PACKAGE_NAME=$(read_info 'name')
PACKAGE_VERSION=$(read_info 'version')
ZIP_NAME=${PACKAGE_NAME}_${PACKAGE_VERSION}
ZIP_FILE=${ZIP_NAME}.zip

# Ensure zip dir exists
if [ ! -d "${ZIP_DIR}" ]; then
    mkdir -p ${BUILD_DIR}/${ZIP_NAME}
fi

# Copy files to zip dir
cp -r \
  ./compatibility \
  ./graphics \
  ./lib \
  ./locale \
  ./prototypes \
  ./sounds \
  ./*.lua \
  ./info.json \
  ./LICENSE \
  ./README.md \
  ./changelog.txt \
  ./thumbnail.png \
  ${BUILD_DIR}/${ZIP_NAME}


# Compress files
cd ${BUILD_DIR}
/usr/bin/zip -r ${ZIP_FILE} ${ZIP_NAME}

# Remove temp dir
rm -rf ${ZIP_NAME}
