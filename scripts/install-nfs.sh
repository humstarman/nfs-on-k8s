#!/bin/bash
DEFAULT_EXPORT="/etc/exports"
show_help () {
cat << USAGE
usage: $0 [ -p NFS-PATH ] [ -e EXPORT-FILE ]
    -p : Specify the path of NFS. 
    -e : Specify the export file for NFS. If not specified, use '${DEFAULT_EXPORT}' by default.
USAGE
exit 0
}
# Get Opts
while getopts "hp:e:" opt; do # 选项后面的冒号表示该选项需要参数
    case "$opt" in
    h)  show_help
        ;;
    p)  NFS=$OPTARG # 参数存在$OPTARG中
        ;;
    e)  EXPORT=$OPTARG
        ;;
    ?)  # 当有不认识的选项的时候arg为?
        echo "unkonw argument"
        exit 1
        ;;
    esac
done
[ -z "$*" ] && show_help
chk_var () {
if [ -z "$2" ]; then
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - no input for \"$1\", try \"$0 -h\"."
  sleep 3
  exit 1
fi
}
chk_var -p $NFS
EXPORT=${EXPORT:-"$DEFAULT_EXPORT"}
if [ -x "$(command -v yum)" ]; then
  yum makecache fast
  yum install -y rpc-bind nfs-utils
else
  echo "$(date -d today +'%Y-%m-%d %H:%M:%S') - [ERROR] - unknown distribution."
  sleep 3
  exit 1
fi
mkdir -p $NFS
[ -f $EXPORT ] || touch $EXPORT
cat > $EXPORT << EOF
$NFS        *(no_root_squash,rw,sync,no_subtree_check)
EOF
systemctl daemon-reload
systemctl enable nfs
systemctl restart nfs
