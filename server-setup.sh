#!/bin/bash
#
#this is setupping Minecraft Server!

yum update
yum upgrade -y
yum install java-21-amazon-corretto-headless.aarch64 cronie -y
systemctl enable crond.service
systemctl start crond.service

adduser minecraft

cd /home/minecraft
echo "downloading..."
wget https://github.com/Usasyuu/AutoStop/releases/latest/download/AutoStop.jar

echo -e "[Unit]
Description=Start AutoStop Service
After=network-online.target

[Service]
Type=forking
WorkingDirectory=/home/minecraft/
ExecStart=screen -S autostop -d -m java -jar AutoStop.jar
ExecStop=sleep 5
Restart=on-failure

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/autostop.service

systemctl enable autostop
systemctl start autostop

echo "フォルダーの名前を入力してください。"
read folder

mkdir ./$folder
chmod 777 /home/minecraft/$folder
sed -i -e "s/LOG_PATH=logs/LOG_PATH=$folder\/logs/" settings.properties

echo -e "[Unit]
Description=Start Minecraft Paper 1.21
After=network-online.target

[Service]
Type=forking
WorkingDirectory=/home/minecraft/$folder/
User=minecraft
ExecStart=screen -S mc -d -m nogui
ExecStop=sleep 10
ExecStop=aws s3 cp $folder s3://minecraftbackup2 --recursive
ExecStop=sleep 20
Restart=on-failure

[Install]
WantedBy=multi-user.target" >> /etc/systemd/system/server.service

sudo systemctl daemon-reload
sudo systemctl enable server.service

job="* */1 * * *  aws s3 cp $folder s3://minecraftbackup2 --recursive"

echo "$job"

crontab -l > /tmp/crontab.temp
echo "$job" >> /tmp/crontab.temp

if crontab -u minecraft /tmp/crontab.temp
then
    echo "crontab install is done successfully."
else
    echo "crontab install is failed."
fi
rm /tmp/crontab.temp