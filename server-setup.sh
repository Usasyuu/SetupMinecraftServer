#!/bin/bash
#
#this is setupping Minecraft Server!

yum update
yum upgrade -y
yum install java-21-amazon-corretto-headless cronie -y
systemctl enable crond.service
systemctl start crond.service

# echo "ユーザー名を入力してください。"
# read user
user="minecraft"
echo "フォルダーの名前を入力してください。"
read folder
echo "割り当てるメモリの量を入力してください。"
read mem


adduser ${user}

cd /home/${user}
echo "downloading..."
curl -OL https://github.com/Usasyuu/AutoStop/releases/latest/download/AutoStop.jar

echo -e "[Unit]
Description=Start AutoStop Service
After=network-online.target

[Service]
Type=forking
WorkingDirectory=/home/${user}/
ExecStart=screen -S autostop -d -m java -Xmx64M -Xms64M -jar AutoStop.jar
ExecStop=sleep 5
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/autostop.service

systemctl enable autostop
systemctl start autostop

mkdir ./${folder}
chown minecraft:minecraft /home/${user}/${folder}

echo -e "[Unit]
Description=Start Minecraft Server
After=network-online.target

[Service]
Type=forking
WorkingDirectory=/home/${user}/${folder}/
User=minecraft
ExecStart=screen -S mc -d -m java -Xmx${mem}G -Xms${mem}G -jar server.jar nogui
ExecStop=screen -p 0 -S mc -X eval 'stuff \"stop\"\\\015'
ExecStop=sleep 10
ExecStop=aws s3 cp ${folder} s3://minecraftbackup2/${folder} --recursive
ExecStop=sleep 20
Restart=on-failure

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/server.service

systemctl daemon-reload
systemctl enable server.service

job="* */1 * * *  aws s3 cp ${folder} s3://minecraftbackup2/${folder} --recursive"

crontab -l > /tmp/crontab.temp
echo "${job}" >> /tmp/crontab.temp

if crontab -u minecraft /tmp/crontab.temp
then
    echo "crontab install is done successfully."
else
    echo "crontab install is failed."
fi
rm /tmp/crontab.temp

sleep 10
sed -i -e "s/LOG_PATH=logs/LOG_PATH=$folder\/logs/" /home/${user}/settings.properties