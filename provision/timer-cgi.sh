#!/bin/bash

# -------------! Задание № 1 !-----------------------------

# Реализация отслеживания в логе слова ALERT и запись этого события в лог messages
# Созание параметров отслеживания. Параметры заносятся в файл /etc/sysconfig/watchlog

sudo cat << EOF > /etc/sysconfig/watchlog
# Configuration file for my watchdog service
# Place it to /etc/sysconfig
# File and word in that file that we will be monit
WORD="ALERT"
LOG=/var/log/watchlog.log
EOF

#  Генерация лог файл который отслеживаем

sudo cat << EOF > /var/log/watchlog.log
ALERT Feb 26 16:49:27 terraform-instance systemd: Started My watchlog service.
ALERT Feb 26 16:48:57 terraform-instance systemd: Started My watchlog service.
EOF

# Скрипт читающий входящий лог файл /var/log/watchlog.log и отслеживающий
# ключевое слово ALERT, а также пишет данные в лог если найдено совпадение.

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

# Служба запускающая скрипт /opt/watchlog.sh обработки лог файла /var/log/watchlog.log

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

# Служба таймера запускающая службу watchlog каждые 30 секунд.

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

# Даем права на исполнение отслеживающего скрипта /opt/watchlog.sh

sudo chmod +x /opt/watchlog.sh

# --------------! Задание № 2 !-------------------------------

# переписать init-скрипт на unit-файл
# Установка необходтмых компанентов
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

# Запускаем сервисы
# Старт spawn-fcgi
systemctl daemon-reload
sudo systemctl start spawn-fcgi
sudo systemctl enable spawn-fcgi
sudo systemctl status spawn-fcgi

# Старт watchlog.timer
sudo systemctl enable watchlog
sudo systemctl start watchlog
sudo systemctl start watchlog.timer
sudo systemctl enable watchlog.timer
sudo systemctl status watchlog.timer
#sudo tail -f /var/log/messages