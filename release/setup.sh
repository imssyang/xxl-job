#!/bin/bash

PROJ_DIR=$(dirname $(dirname $(readlink -f "$0")))
PROJ_NAME=$(basename $PROJ_DIR)
RELE_DIR=$PROJ_DIR/release
SYSD_DIR=/etc/systemd/system
SERV_ADMIN=xxl-job-admin.service
SERV_EXECUTOR=xxl-job-executor.service

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

run_admin() {
  debug java -Xms512m -Xmx1024m \
    -DLOG_HOME=$RELE_DIR/logs \
    -Dspring.config.location=classpath:/application.properties,file:$RELE_DIR/xxl-job-admin.properties \
    -jar $RELE_DIR/xxl-job-admin-3.2.1.jar
}

run_executor() {
  debug java -Xms512m -Xmx1024m \
    -DLOG_HOME=$RELE_DIR/logs \
    -Dspring.config.location=classpath:/application.properties,file:$RELE_DIR/xxl-job-executor.properties \
    -jar $RELE_DIR/xxl-job-executor-3.2.1.jar
}

case "$1" in
  show)
    echo "Name: $PROJ_NAME"
    echo "Home: $PROJ_DIR"
    ;;
  run)
    shift; name=$1; shift
    if [[ "$name" == "admin" ]]; then
      run_admin $@
    elif [[ "$name" == "executor" ]]; then
      run_executor $@
    else
      echo "Invalid params: $name"
    fi
    ;;
  install)
    enable_service $SERV_ADMIN
    enable_service $SERV_EXECUTOR
    ;;
  uninstall)
    disable_service $SERV_ADMIN
    disable_service $SERV_EXECUTOR
    ;;
  *)
    echo "Usage: ${0##*/} {show|run|install|uninstall}"
    ;;
esac

exit 0
