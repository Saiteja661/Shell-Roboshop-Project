#!/bin/bash

USERID=$(id -u)
LOG_FOLDER="/var/log/shell-roboshop"
LOG_FILE="$LOG_FOLDER/$0.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

SCRIPT_DIR=$PWD
RABBITMQ_HOST="rabbitmq.saiteja.shop"
DISPATCHER_HOST="dispatcher.saiteja.shop"

if [ $USERID -ne 0 ]; then
  echo -e "${R}You should run this script as root user or with sudo privileges${N}" | tee -a $LOG_FILE
  exit 1
fi

VALIDATE() {
  if [ $1 -ne 0 ]; then
    echo -e "${R}FAIL${N}"
    echo -e "${Y}Check the log file for more details: $LOG_FILE${N}" | tee -a $LOG_FILE
    exit 1
  else
    echo -e "${G}SUCCESS${N}" | tee -a $LOG_FILE
  fi

dnf install python3 gcc python3-devel -y    &>>$LOG_FILE
VALIDATE $? "installing dependencies"

id roboshop    &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "creating roboshop user"
else
    echo -e "${Y}User 'roboshop' already exists. Skipping user creation.${N}" | tee -a $LOG_FILE
fi      

mkdir /app    &>>$LOG_FILE
VALIDATE $? "creating application directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip   &>>$LOG_FILE
VALIDATE $? "downloading application code"

cd /app    &>>$LOG_FILE

rm -rf /app/*    &>>$LOG_FILE
VALIDATE $? "cleaning application directory"

unzip /tmp/payment.zip    &>>$LOG_FILE
VALIDATE $? "extracting application code"

cd /app
pip3 install -r requirements.txt    &>>$LOG_FILE
VALIDATE $? "installing application dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service    &>>$LOG_FILE
VALIDATE $? "copying systemd service file"

systemctl daemon-reload    &>>$LOG_FILE
VALIDATE $? "reloading systemd daemon"

systemctl enable payment    &>>$LOG_FILE
systemctl start payment    &>>$LOG_FILE
VALIDATE $? "starting payment service"