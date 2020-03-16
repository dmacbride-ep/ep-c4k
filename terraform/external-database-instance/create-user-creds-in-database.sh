#!/usr/bin/env bash

error() {
  echo "ERROR: $1"
  exit 1
}

info() {
  echo "INFO: $1"
}

debug() {
  echo "DEBUG: $1"
}

if [[ -z "$mysql_database" ]]; then
  error "mysql_database must be set to a database of the mysql server"
fi

if [[ -z "$mysql_root_user" ]]; then
  error "mysql_root_user must be set to the username of the root database user"
fi

if [[ -z "$mysql_root_password" ]]; then
  error "mysql_root_password must be set to the password of the root database user"
fi

if [[ -z "$mysql_new_user" ]]; then
  error "mysql_new_user must be set to the new user to be created in the database"
fi

if [[ -z "$mysql_new_password" ]]; then
  error "mysql_new_password must be set to the new password for mysql_new_user"
fi

if [[ -z "$mysql_hostname" ]]; then
  error "mysql_hostname must be set to the database server name"
fi

if [[ -z "$mysql_server_url" ]]; then
  error "mysql_server_url must be set to the url of the database server"
fi

if [[ ${cloud} == "azure" ]]; then
  full_root_user="${mysql_root_user}@${mysql_hostname}"
else
  full_root_user=${mysql_root_user}

  mysql -h "${mysql_server_url}" -u"${full_root_user}" -p"${mysql_root_password}" -e "CREATE DATABASE ${mysql_database};" || info "Skipping database creation"
fi

userExists=$(mysql -h "${mysql_server_url}" -u"${full_root_user}" -p"${mysql_root_password}" -e "SELECT COUNT(*) FROM mysql.user WHERE user = '${mysql_new_user}';" | tail -n1)

if [[ ! ${userExists} == "1" ]]; then
  queries="
  CREATE USER '${mysql_new_user}'@'%' IDENTIFIED BY '${mysql_new_password}';
  GRANT ALL PRIVILEGES ON ${mysql_database}.* TO '${mysql_new_user}'@'%';
  FLUSH PRIVILEGES;
  "

  mysql -h "${mysql_server_url}" -u"${full_root_user}" -p"${mysql_root_password}" -D "${mysql_database}" -e "${queries}"
else
  info "User ${mysql_new_user} already exists"
fi