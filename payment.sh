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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "installing python3"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]
then    
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating roboshop system user"
else
    echo -e "system user roboshop already created...$Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
VALIDATE $? "downloading payment"

rm -rf /app*
cd /app 
unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzipping payment"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "installing dependencies"

cp $SCRIPT_NAME/payment.service /etc/systemd/system/payment.service &>>$LOG_FILE
VALIDATE $? "copying payment service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "daemon reload"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "enabling payment"

systemctl start payment &>>$LOG_FILE
VALIDATE $? "starting payment"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $START_TIME - $END_TIME ))

echo -e "script execution successfully completed, $Y time take: $TOTAL_TIME $N" | tee -a $LOG_FILE