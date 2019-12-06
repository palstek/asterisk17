FROM ubuntu:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y \
  vim \
  wget \
  fail2ban \
  build-essential \
  libssl-dev \
  libxml2-dev \
  sqlite3 \
  libsqlite3-dev \
  libncurses5-dev \
  libedit-dev \
  uuid-dev && \
  cd /usr/src && \
  ### Download Asterisk
  wget http://downloads.asterisk.org/pub/telephony/asterisk/asterisk-17-current.tar.gz && \
  tar -zxvf asterisk-17-current.tar.gz && \
  rm asterisk-17-current.tar.gz && \
  cd /usr/src/asterisk* && \
  ### Install Asterisk Dependencies
  echo y | ./contrib/scripts/install_prereq install && \
  echo y | ./contrib/scripts/get_mp3_source.sh && \
  ### Install Asterisk
  ./configure --with-jansson-bundled --with-crypto --with-ssl && \
  make menuselect.makeopts && \
  menuselect/menuselect \
  --disable BUILD_NATIVE \
  --enable format_mp3 \
  --disable-category MENUSELECT_CORE_SOUNDS \
  --disable-category MENUSELECT_MOH \
  --disable-category MENUSELECT_EXTRA_SOUNDS \
  menuselect.makeopts && \
  cd /usr/src/asterisk* && make && make install && make samples && ldconfig && \
  ### Backup original conf files
  for f in /etc/asterisk/*.conf; do cp -- "$f" "${f%.conf}.sample"; done && \
  mkdir /etc/asterisk/samples && mv /etc/asterisk/*.sample /etc/asterisk/samples/ && \
  ### Make conf files prettier
  for f in /etc/asterisk/*.conf; do sed -i '/^$/d' $f; sed -i '/^\s*;/d' $f; done && \
  ### Configure for fail2ban
  rm /etc/fail2ban/jail.d/defaults-debian.conf && \
  echo [asterisk] >> /etc/fail2ban/jail.d/asterisk.conf && \
  echo enabled=true >> /etc/fail2ban/jail.d/asterisk.conf && \
  sed -i 's/protocol = tcp/protocol = all/' /etc/fail2ban/jail.conf && \
  update-rc.d fail2ban enable && \
  touch /var/log/asterisk/messages && \
  service fail2ban start && \
  ### Clean up files
  rm -rf /etc/cron* && \
  apt-get -y autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

EXPOSE 5060 5061

VOLUME /etc/asterisk /var/lib/asterisk /var/spool/asterisk

CMD ["asterisk", "-cvvvv"]
