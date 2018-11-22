#!/bin/bash
#author: itnihao
red='\e[0;31m' # 红色  
RED='\e[1;31m' 
green='\e[0;32m' # 绿色  
GREEN='\e[1;32m' 
blue='\e[0;34m' # 蓝色  
BLUE='\e[1;34m' 
purple='\e[0;35m' # 紫色  
PURPLE='\e[1;35m' 
NC='\e[0m' # 没有颜色  
source /etc/bashrc
source /etc/profile
MySQL_USER=zabbix
MySQL_PASSWORD=zabbix
MySQL_HOST=localhost
MySQL_PORT=3306
MySQL_DUMP_PATH=/opt/mysql_bak/zabbix-datafile-backup
MYSQL_BIN_PATH=/opt/mysql57/bin/mysql
MYSQL_DUMP_BIN_PATH=/opt/mysql57/bin/mysqldump
MySQL_DATABASE_NAME=zabbix
DATE=$(date '+%Y%m%d')
MySQLDUMP () {
    [ -d ${MySQL_DUMP_PATH} ] || mkdir ${MySQL_DUMP_PATH}
    cd ${MySQL_DUMP_PATH}
    [ -d logs    ] || mkdir logs
    [ -d ${DATE} ] || mkdir ${DATE}
    cd ${DATE}
     
    #TABLE_NAME_ALL=$(${MYSQL_BIN_PATH} -u${MySQL_USER} -p${MySQL_PASSWORD}  -h${MySQL_HOST} ${MySQL_DATABASE_NAME} -e "show tables"|egrep -v "(Tables_in_zabbix)")
#    TABLE_NAME_ALL=$(${MYSQL_BIN_PATH} -u${MySQL_USER} -p${MySQL_PASSWORD}  -h${MySQL_HOST} ${MySQL_DATABASE_NAME} -e "show tables"|egrep -v "(Tables_in_zabbix|history*|trends*|acknowledges|alerts|auditlog|events|service_alarms)")
    TABLE_NAME_ALL=$(${MYSQL_BIN_PATH} --defaults-extra-file=/etc/my.cnf ${MySQL_DATABASE_NAME} -e "show tables"|egrep -v "(Tables_in_zabbix|history*|trends*|acknowledges|alerts|auditlog|events|service_alarms|sessions)")
    for TABLE_NAME in ${TABLE_NAME_ALL}
    do
        ${MYSQL_DUMP_BIN_PATH} --defaults-extra-file=/etc/my.cnf --opt ${MySQL_DATABASE_NAME} ${TABLE_NAME} >${TABLE_NAME}.sql
#        ${MYSQL_DUMP_BIN_PATH}  --opt -u${MySQL_USER} -p${MySQL_PASSWORD} -P${MySQL_PORT} -h${MySQL_HOST} ${MySQL_DATABASE_NAME} ${TABLE_NAME} >${TABLE_NAME}.sql
        sleep 0.01
    done
    [ "$?" == 0 ] && echo "${DATE}: Backup zabbix succeed"     >> ${MySQL_DUMP_PATH}/logs/ZabbixMysqlDump.log
    [ "$?" != 0 ] && echo "${DATE}: Backup zabbix not succeed" >> ${MySQL_DUMP_PATH}/logs/ZabbixMysqlDump.log
     
    cd ${MySQL_DUMP_PATH}/
	tar -zcf $DATE.tar.gz $DATE
	rm -rf $DATE
#    rm -rf $(date +%Y%m%d --date='5 days ago').tar.gz
    exit 0
}
MySQLImport () {
    cd ${MySQL_DUMP_PATH}
    DATE=$(ls  ${MySQL_DUMP_PATH} |egrep "\b^[0-9]+$\b")
    echo -e "${green}${DATE}"
    echo -e "${blue}what DATE do you want to import,please input date:${NC}"
    read SELECT_DATE
    if [ -d "${SELECT_DATE}" ];then
        echo -e "you select is ${green}${SELECT_DATE}${NC}, do you want to contine,if,input ${red}(yes|y|Y)${NC},else then exit"
        read Input
        [[ 'yes|y|Y' =~ "${Input}" ]]
        status="$?"
        if [ "${status}" == "0"  ];then
            echo "now import SQL....... Please wait......."
        else
            exit 1
        fi
        cd ${SELECT_DATE}
        for PER_TABEL_SQL in $(ls *.sql)
        do
           ${MYSQL_BIN_PATH} -u${MySQL_USER} -p${MySQL_PASSWORD}  -h${MySQL_HOST} ${MySQL_DATABASE_NAME} < ${PER_TABEL_SQL}
           echo -e "import ${PER_TABEL_SQL} ${PURPLE}........................${NC}"
        done 
        echo "Finish import SQL,Please check Zabbix database"
    else 
        echo "Don't exist ${SELECT_DATE} DIR" 
    fi
}
case "$1" in
MySQLDUMP|mysqldump)
    MySQLDUMP
    ;;
MySQLImport|mysqlimport)
    MySQLImport
    ;;
*)
    echo "Usage: $0 {(MySQLDUMP|mysqldump) (MySQLImport|mysqlimport)}"
    ;;
esac
