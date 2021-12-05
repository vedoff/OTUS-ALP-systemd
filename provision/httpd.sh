# Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами
#sudo sed -i 's!EnvironmentFile=/etc/sysconfig/httpd!EnvironmentFile=/etc/sysconfig/httpd/%I!' /usr/lib/systemd/system/httpd.service

#sudo sed -i '/Listen 80/d' /etc/httpd/conf/httpd.conf

# Создаем Unit для запуска Apach

sudo cat << EOF > /etc/systemd/system/httpd@.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
Documentation=man:httpd(8)
Documentation=man:apachectl(8)

[Service]
Type=notify
EnvironmentFile=/etc/sysconfig/httpd-first
EnvironmentFile=/etc/sysconfig/httpd-second
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

# Запускаем сервисы проверяем.
sudo systemctl daemon-reload
sudo systemctl start httpd@first
sudo systemctl start httpd@second
sudo ss -tnulp | grep httpd