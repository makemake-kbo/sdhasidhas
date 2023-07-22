STARTS=$1
INIT_HASH=
if [ -n "$2" ]; then
  INIT_HASH=--init-code-hash $2
fi
EXTRA_ARGS=
if [ -n "$3" ]; then
  EXTRA_ARGS=$3
fi

cast create2 --starts-with $1 $2 $3
