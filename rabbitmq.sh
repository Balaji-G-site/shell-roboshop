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

cp $SCRIPT_NAME/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "copying rabbitmq"

dnf install rabbitmq-server -y &>>&LOG_FILE
VALIDATE $? "installing rabbitmq"

systemctl enable rabbitmq-server &>>&LOG_FILE
VALIDATE $? "enabling rabitmq-server"

systemctl start rabbitmq-server &>>&LOG_FILE
VALIDATE $? "startinf rabbitmq-server"

rabbitmqctl add_user roboshop $RABBITMQ_PASSWD &>>&LOG_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>>&LOG_FILE

END_TIME=$(date +%s)
TOTAL_TIME=$(( $START_TIME - $END_TIME ))

echo -e "script execution successfully completed, $Y time take: $TOTAL_TIME $N" | tee -a $LOG_FILE