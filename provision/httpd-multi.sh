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
EnvironmentFile=/etc/sysconfig/httpd-%I
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
# Добавляем конфиг для запуска httpd first.conf

sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
sudo sed -i 's/Listen 80/Listen 8000/g' /etc/httpd/conf/first.conf
sudo sh -c "echo 'PidFile /var/run/httpd-first.pid' >> /etc/httpd/conf/first.conf"


# Добавляем конфигурационный файл окружения №2

sudo cat << EOF > /etc/sysconfig/httpd-second
OPTIONS=-f conf/second.conf
EOF
# Добавляем конфиг для запуска httpd second.conf

sudo cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
sudo sed -i 's/Listen 80/Listen 8001/g' /etc/httpd/conf/second.conf
sudo sh -c "echo 'PidFile /var/run/httpd-second.pid' >> /etc/httpd/conf/second.conf"

# Запускаем сервисы проверяем.
sudo systemctl daemon-reload
sudo systemctl start httpd@first
sudo systemctl enable httpd@first
sudo systemctl start httpd@second
sudo systemctl enable httpd@second
sudo ss -tnulp