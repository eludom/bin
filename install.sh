#! /bin/bash
#
# create ~/bin and symlink all files here into ~/bin/
#
# This is a special case.  We have to install link2 and linkall by hand to use them.

set -e -u


# Get the path to this (install.sh) script.
#   See http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

echo DIR $DIR

mkdir -p $HOME/bin

# bootstrap

${DIR}/link2 -r ${DIR}/link2 ~/bin/link2
${DIR}/link2 -r ${DIR}/linkall ~/bin/linkall

# link the rest

~/bin/linkall $DIR ~/bin/


# See what we've done

ls -l ~/bin

# get rid of ~/bin/install.sh as it's too generic of a name and specific to this directory

rm ~/bin/install.sh
