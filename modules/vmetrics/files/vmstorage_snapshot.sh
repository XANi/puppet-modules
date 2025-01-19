# puppet managed file

PORT=$1
DIR=$2
if [ -z "$a" ] ;then
    echo "usage $0 port local_path"
fi
SNAPSHOT_ID=$(curl -s http://127.0.0.1:${PORT}/snapshot/create | jq -r .snapshot)
cd $DIR || exit 1
if [ ! -e $SNAPSHOT_ID ] ; then
  echo "snapshot failed [$SNAPSHOT_ID]"
  exit 2
fi
rm -rf /var/lib/victoriametrics/data/snapshots/current
IN=$SNAPSHOT_ID
OUT=current
for a in `find -L "$IN"  -type f` ; do
  p=${a#$IN/} # cut first element from path
  #echo $p
  mkdir -p $OUT/`dirname $p`
  ln $a $OUT/$p
done
if   curl -s http://127.0.0.1:8482/snapshot/delete_all | grep -v '"ok"' ; then
  echo "cleaning snapshots failed"
fi
