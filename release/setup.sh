#!/bin/bash

PROJ_DIR=$(dirname $(dirname $(readlink -f "$0")))
PROJ_NAME=$(basename $PROJ_DIR)
SYSD_DIR=/etc/systemd/system
SERV_ADMIN=xxl-job-admin.service

debug() { echo "+ $*"; "$@"; }

symlink_create() {
  if [[ ! -d $2 ]] && [[ ! -s $2 ]]; then
    ln -s $1 $2
    echo "($PROJ_NAME) create symlink: $2 -> $1"
  fi
}

symlink_delete() {
  if [[ -d $1 ]] || [[ -s $1 ]]; then
    rm -rf $1
    echo "($PROJ_NAME) delete symlink: $1"
  fi
}

enable_service() {
  symlink_create $PROJ_DIR/release/$1 $SYSD_DIR/$1
  systemctl enable $1
  systemctl daemon-reload
}

disable_service() {
  systemctl disable $1
  systemctl daemon-reload
  symlink_delete $SYSD_DIR/$1
}

run_xxl_job_admin() {
  xxl_dir=$PROJ_DIR/release
  debug java -Xms512m -Xmx1024m \
    -DLOG_HOME=$xxl_dir/logs \
    -Dspring.config.location=classpath:/application.properties,file:$xxl_dir/xxl-job-admin.properties \
    -jar $xxl_dir/xxl-job-admin-3.2.1.jar
}

case "$1" in
  show)
    echo "Name: $PROJ_NAME"
    echo "Home: $PROJ_DIR"
    ;;
  run)
    run_xxl_job_admin $@
    ;;
  install)
    enable_service $SERV_ADMIN
    ;;
  uninstall)
    disable_service $SERV_ADMIN
    ;;
  *)
    echo "Usage: ${0##*/} {show|run|install|uninstall}"
    ;;
esac

exit 0
