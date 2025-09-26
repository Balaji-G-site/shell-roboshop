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

dnf module disable nodejs -y &>>LOG_FILE
VALIDATE $? "disabling nodejs"

dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "enabling nodejs"

dnf insatll nodejs -y &>>LOG_FILE
VALIDATE $? "installing nodejs"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>LOG_FILE
    VALIDATE $? "creating roboshop system user"
else
    echo -e "system user roboshop already present...$Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "creating app directory"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip &>>LOG_FILE
VALIDATE $? "downloading cart"

rm -rf /app*
cd /app 
unzip /tmp/cart.zip &>>LOG_FILE
VALIDATE $? "unzipping cart"

npm insatll &>>LOG_FILE
VALIDATE $? "installing dependencies"

cp $SCRIPT_NAME/cart.service /etc/systemd/system/cart.service
VALIDATE $? "copying cart service"

systemctl daemon-reload &>>LOG_FILE
systemctl enable cart &>>LOG_FILE
systemctl start cart
VALIDATE $? "starting cart"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $START_TIME - $END_TIME ))

echo -e "script execution successfully completed,$Y time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE