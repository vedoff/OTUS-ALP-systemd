#!/bin/bash

# Реализация отслеживания в логе слова ALERT и запись этого события в лог messages

sudo cat << EOF > /etc/sysconfig/watchlog
# Configuration file for my watchdog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
EOF



sudo cat << EOF > /var/log/watchlog.log
ALERT Feb 26 16:49:27 terraform-instance systemd: Started My watchlog service.
ALERT Feb 26 16:48:57 terraform-instance systemd: Started My watchlog service.
EOF

sudo cat << EOF > /opt/watchlog.sh
#!/bin/bash
WORD=\$1
LOG=\$2
DATE=\$(date)
if grep \$WORD \$LOG &> /dev/null
then
logger "\$DATE: I found word, Master!"
else
exit 0
fi
EOF

sudo cat << EOF > /etc/systemd/system/watchlog.service
[Unit]
Description=My watchlog service
[Service]
Type=oneshot
EnvironmentFile=/etc/sysconfig/watchlog
ExecStart=/opt/watchlog.sh \$WORD \$LOG
[Install]
WantedBy=multi-user.target
EOF

sudo cat << EOF > /etc/systemd/system/watchlog.timer
[Unit]
Description=Run watchlog script every 30 second
[Timer]
# Run every 30 second
OnUnitActiveSec=30
Unit=watchlog.service
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start watchlog.timer

# переписать init-скрипт на unit-файл

sudo yum install epel-release -y && sudo yum install spawn-fcgi php php-cli mod_fcgid httpd -y

# Удаление # в строках которые начинаются с SOCKET и OPTIONS в файле spawn-fcgi

sudo sed -i '/SOCKET=/s/^#\+//' /etc/sysconfig/spawn-fcgi
sudo sed -i '/OPTIONS=/s/^#\+//' /etc/sysconfig/spawn-fcgi

# Добавление юнита spawn-fcgi.service

sudo cat << EOF > /etc/systemd/system/spawn-fcgi.service
[Unit]
Description=Spawn-fcgi startup service by Otus
After=network.target
[Service]
Type=simple
PIDFile=/var/run/spawn-fcgi.pid
EnvironmentFile=/etc/sysconfig/spawn-fcgi
ExecStart=/usr/bin/spawn-fcgi -n \$OPTIONS
KillMode=process
[Install]
WantedBy=multi-user.target
EOF

sudo systemctl start spawn-fcgi
sudo systemctl status spawn-fcgi

# Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами
#sudo sed -i 's!EnvironmentFile=/etc/sysconfig/httpd!EnvironmentFile=/etc/sysconfig/httpd/%I!' /usr/lib/systemd/system/httpd.service

sudo sed -i '/Listen 80/d' /etc/httpd/conf/httpd.conf

# Создаем Unit для запуска Apach

sudo cat << EOF > /etc/systemd/system/httpd@.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/%I
ExecStart=/usr/sbin/httpd \$OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd \$OPTIONS -k graceful
ExecStop=/bin/kill -WINCH \${MAINPID}
KillSignal=SIGCONT
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF



# Добавляем конфигурационный файл окружения №1

sudo cat << EOF > /etc/sysconfig/httpd-first
OPTIONS=-f conf/first.conf
EOF
sudo cat << EOF > /etc/httpd/conf/first.conf
PidFile /var/run/httpd-first.pid
Listen 8000
EOF

# Добавляем конфигурационный файл окружения №2

sudo cat << EOF > /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
EOF

sudo cat << EOF > /etc/httpd/conf/second.conf
PidFile /var/run/httpd-second.pid
Listen 8080
EOF

sudo systemctl daemon-reload

sudo systemctl start httpd@first
sudo systemctl start httpd@second
sudo ss -tnulp | grep httpd


