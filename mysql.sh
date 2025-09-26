#!/bin/bash

START_TIME=(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
LOGS_FOLDER="/var/log/shellscript-logs"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"

mkdir -p $LOGS_FOLDER
echo "script start executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR: Please run this script with root user $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

VALIDATE () {
    if [ $1 -eq 0 ]
    then
        echo -e "installing $2 is...$G SUCCESSFUL $N" | tee -a $LOG_FILE
    else
        echo -e "installing $2 is...$R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install mysql-server -y &>>$LOG_FILE
VALIDATE $? "installing mysql"

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "enabling mysql"

systemctl start mysqld  &>>$LOG_FILE
VALIDATE $? "starting mysql"

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD &>>$LOG_FILE
VALIDATE $? "setting mysql root password"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $START_TIME - $END_TIME ))

echo -e "script execution successfully completed, $Y time take: $TOTAL_TIME $N" | tee -a $LOG_FILE