#!/usr/bin/env bash
set -eo pipefail
IFS=$'\n\t'

if [[ -z $TRAVIS_TAG ]]; then
  TRAVIS_TAG=$(git describe --tags)
fi

set -u

BINARY_NAME=vn

GIT_SHA=$(git rev-parse HEAD)
VERSION=${TRAVIS_TAG#"v"}

DIRTY=""
$(git diff-index --quiet HEAD 2>/dev/null) || DIRTY=".DIRTY"

if [[ ! -d ./dist ]]; then
  mkdir ./dist
fi

echo "Building version ${VERSION}${DIRTY}"

BUILD_LDFLAGS="-X github.com/venuenext/venuenext-cli/commands.Version=${VERSION}${DIRTY} -X github.com/venuenext/venuenext-cli/commands.GitRevision=$(git rev-parse HEAD)${DIRTY}"

echo "Starting the Build (macOS 64-bit)"
GOOS=darwin GOARCH=amd64 go build -o ${BINARY_NAME} -ldflags ${BUILD_LDFLAGS} ./cmd/${BINARY_NAME}

case "$OSTYPE" in
  darwin*)  echo "Making sure the build runs (macOS)" && ./${BINARY_NAME} ;;
esac

echo "Making tar.bz2 package for distribution (macOS 64-bit)"
tar cfvj dist/${BINARY_NAME}_macos64.tar.bz2 ./${BINARY_NAME}

echo "SHA256 Sum of the distribution"
shasum -a 256 dist/${BINARY_NAME}_macos64.tar.bz2 > dist/${BINARY_NAME}_macos64.tar.bz2.sha256
MACOS_SHA=$(awk '{ print $1 }' dist/${BINARY_NAME}_macos64.tar.bz2.sha256)
cat dist/${BINARY_NAME}_macos64.tar.bz2.sha256

echo "Starting the Build (linux amd64)"
GOOS=linux GOARCH=amd64 go build -o ${BINARY_NAME} -ldflags ${BUILD_LDFLAGS} ./cmd/${BINARY_NAME}

case "$OSTYPE" in
  linux*)   echo "Making sure the build runs (linux)" && ./${BINARY_NAME} ;;
esac

echo "Making tar.bz2 package for distribution (linux amd64)"
tar cfvj dist/${BINARY_NAME}_linux64.tar.bz2 ./${BINARY_NAME}

echo "SHA256 Sum of the distribution"
shasum -a 256 dist/${BINARY_NAME}_linux64.tar.bz2 > dist/${BINARY_NAME}_linux64.tar.bz2.sha256

echo "Starting the Build (windows amd64)"
GOOS=windows GOARCH=amd64 go build -o ${BINARY_NAME}.exe -ldflags ${BUILD_LDFLAGS} ./cmd/${BINARY_NAME}

case "$OSTYPE" in
  msys*)    echo "Making sure the build runs (windows)" && ./${BINARY_NAME} ;;
esac

echo "Making tar.bz2 package for distribution (windows amd64)"
tar cfvj dist/${BINARY_NAME}_win64.tar.bz2 ./${BINARY_NAME}.exe

echo "SHA256 Sum of the distribution"
shasum -a 256 dist/${BINARY_NAME}_win64.tar.bz2 > dist/${BINARY_NAME}_win64.tar.bz2.sha256


echo "done building..."
