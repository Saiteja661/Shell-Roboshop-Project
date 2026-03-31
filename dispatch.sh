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


if [ $USERID -ne 0 ]; then
  echo -e "\e[31mYou should run this script as root user or with sudo privileges\e[0m"
  exit 1
fi

VALIDATE() {
  if [ $1 -ne 0 ]; then
    echo -e "\e[31mFAIL\e[0m"
    exit 1
  else
    echo -e "\e[32mSUCCESS\e[0m"
  fi
}


dnf install golang -y &>>$LOG_FILE
VALIDATE $? "Golang Installation"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Adding Roboshop User"
else    
    echo -e "\e[33mRoboshop user already exists, skipping user creation\e[0m"
fi

mkdir /app &>>$LOG_FILE
VALIDATE $? "Creating Application Directory"

curl -L -o /tmp/dispatch.zip https://roboshop-artifacts.s3.amazonaws.com/dispatch-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading Dispatch Application"

cd /app

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Cleaning Old Content"

unzip /tmp/dispatch.zip &>>$LOG_FILE
VALIDATE $? "Extracting Dispatch Content"

cd /app &>>$LOG_FILE
go mod init dispatch &>>$LOG_FILE
VALIDATE $? "Initializing Go Modules"

go get &>>$LOG_FILE
VALIDATE $? "Downloading Go Dependencies"

go build &>>$LOG_FILE
VALIDATE $? "Building Dispatch Application"

cp $SCRIPT_DIR/dispatch.service /etc/systemd/system/dispatch.service &>>$LOG_FILE
VALIDATE $? "Copying Systemd Service File"

systemctl daemon-reload &>>$LOG_FILE
systemctl enable dispatch &>>$LOG_FILE
systemctl start dispatch &>>$LOG_FILE
VALIDATE $? "Starting Dispatch Service"