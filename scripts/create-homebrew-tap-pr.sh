#!/bin/bash

[ -z ${VERSION+x} ] && { echo "VERSION is missing"; exit 1; }

FILE_X64=brew-distribution/danger-macos-x64.zip
FILE_ARM64=brew-distribution/danger-macos-arm64.zip

if [ ! -f ${FILE_X64} ]; then
  echo ${FILE_X64} not found!
  exit 1
fi
if [ ! -f ${FILE_ARM64} ]; then
  echo ${FILE_ARM64} not found!
  exit 1
fi

SHA_X64=$(shasum -a 256 ${FILE_X64} | cut -f 1 -d " ")
echo "SHA_X64=$SHA_X64"
SHA_ARM64=$(shasum -a 256 ${FILE_ARM64} | cut -f 1 -d " ")
echo "SHA_ARM64=$SHA_ARM64"

mkdir -p ~/.ssh
echo "${HOMEBREW_TAP_EXP_DEPLOY_KEY}" > ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
git config --global user.name danger
git config --global user.email danger@users.noreply.github.com
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
echo "$ ssh-add -L"
ssh-add -L
echo "$ ssh-keyscan"
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
echo "# ssh -vT git@github.com"
ssh -o StrictHostKeyChecking=no -F /dev/null -vT git@github.com
# ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no -F /dev/null

# Clone tap repo
HOMEBREW_TAP_TMPDIR=$(mktemp -d)
echo "HOMEBREW_TAP_TMPDIR=$HOMEBREW_TAP_TMPDIR" # H| Remove later
# git clone --depth 1 https://github.com/danger/homebrew-tap.git "$HOMEBREW_TAP_TMPDIR"
git clone --depth 1 git@github.com:pepix/homebrew-tap-exp.git "$HOMEBREW_TAP_TMPDIR" # H| Fix later
cd "$HOMEBREW_TAP_TMPDIR" || exit 1

# Write formula
echo "class DangerJs < Formula" > danger-js.rb
echo "  homepage \"https://github.com/danger/danger-js\"" >> danger-js.rb
echo >> danger-js.rb
echo "  if Hardware::CPU.intel?" >> danger-js.rb
echo "    url \"https://github.com/danger/danger-js/releases/download/${VERSION}/danger-macos-x64.zip\"" >> danger-js.rb
echo "    sha256 \"${SHA_X64}\"" >> danger-js.rb
echo >> danger-js.rb
echo "    def install" >> danger-js.rb
echo "      bin.install \"danger-x64\" => \"danger\"" >> danger-js.rb
echo "    end" >> danger-js.rb
echo "  end" >> danger-js.rb
echo >> danger-js.rb
echo "  if Hardware::CPU.arm?" >> danger-js.rb
echo "    url \"https://github.com/danger/danger-js/releases/download/${VERSION}/danger-macos-arm64.zip\"" >> danger-js.rb
echo "    sha256 \"${SHA_ARM64}\"" >> danger-js.rb
echo >> danger-js.rb
echo "    def install" >> danger-js.rb
echo "      bin.install \"danger-arm64\" => \"danger\"" >> danger-js.rb
echo "    end" >> danger-js.rb
echo "  end" >> danger-js.rb
echo "end" >> danger-js.rb

# Commit changes
git add danger-js.rb
git commit -m "Releasing danger-js version ${VERSION}"
git remote rm origin
git remote add origin git@github.com:pepix/homebrew-tap-exp.git # H| Update later
git push origin master
