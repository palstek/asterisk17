FROM ubuntu:18.04

ARG DEBIAN_FRONTEND=noninteractive
RUN apt update -y && apt upgrade -y && apt install -y -qq g++ make wget patch libedit-dev uuid-dev libjansson-dev libxml2-dev sqlite3 libsqlite3-dev libssl-dev mpg123 libespeak-ng-dev libsamplerate0-dev mbrola mbrola-de1 mbrola-de2 mbrola-de3 mbrola-de4 mbrola-de5 mbrola-de6 mbrola-de7
WORKDIR /usr/src
RUN wget https://downloads.asterisk.org/pub/telephony/asterisk/asterisk-17-current.tar.gz
RUN tar xvzf asterisk-17-current.tar.gz && rm asterisk-17-current.tar.gz
WORKDIR asterisk-17.4.0
RUN echo y | ./contrib/scripts/install_prereq install && echo y | ./contrib/scripts/get_mp3_source.sh
RUN ./configure
RUN make menuselect.makeopts
RUN menuselect/menuselect --disable BUILD_NATIVE \
  --enable format_mp3 \
  --disable-category MENUSELECT_CORE_SOUNDS \
  --disable-category MENUSELECT_MOH \
  --disable-category MENUSELECT_EXTRA_SOUNDS \
  menuselect.makeopts
RUN make -j4 && make -j4 install && make -j4 samples && ldconfig && \
  ### Backup original conf files
  for f in /etc/asterisk/*.conf; do cp -- "$f" "${f%.conf}.sample"; done && \
  mkdir /etc/asterisk/samples && mv /etc/asterisk/*.sample /etc/asterisk/samples/ && \
  ### Make conf files prettier
  for f in /etc/asterisk/*.conf; do sed -i '/^$/d' $f; sed -i '/^\s*;/d' $f; done && \
  ### Copy header files to system directory
  cp -a include/* /usr/include/ && \
  ### Clean up files
  apt-get -y autoremove && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /usr/src/*

WORKDIR /usr/src
RUN wget https://github.com/zaf/Asterisk-eSpeak/archive/v5.0-rc1.tar.gz
RUN tar xvzf v5.0-rc1.tar.gz && rm v5.0-rc1.tar.gz
WORKDIR Asterisk-eSpeak-5.0-rc1
RUN make && make install && \
  rm -rf /usr/src/*

WORKDIR /etc/asterisk

EXPOSE 5060 5061

VOLUME /etc/asterisk /var/lib/asterisk /var/spool/asterisk

CMD ["asterisk", "-f"]
