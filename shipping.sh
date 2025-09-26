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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "installing maven"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating roboshop system user"
else
    echo -e "system user roboshop already present...$Y SKIPPING $N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading shipping"

rm -rf /app*
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzipping shipping"

mvn clean package &>>$LOG_FILE
VALIDATE $? "packing the shipping application"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "moving and renaming jar file"

cp $SCRIPT_NAME/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "enabling shipping"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "starting shipping"

dnf install mysql -y &>>$LOG_FILE
VALIDATE $? "installing mysql"

mysql -h mysql.gundlapalli.site -uroot -pMYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [$? -ne 0 ]
then
    mysql -h mysql.gundlapalli.site -uroot -pMYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.gundlapalli.site -uroot -pMYSQL_ROOT_PASSWORD < /app/db/app-user.sql &>>$LOG_FILE
    mysql -h mysql.gundlapalli.site -uroot -pMYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Data loading into MySql"
else 
    echo -e "data is already loaded into mysql...$Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "restarting shipping"

END_TIME=(date +%s)
TOTAL_TIME=$(( $START_TIME - $END_TIME ))

echo -e "script execution successfully completed, $Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE