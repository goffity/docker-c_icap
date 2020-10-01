FROM alpine:latest

LABEL maintainer "nkapashi"

ENV cicapBaseVersion="0.5.6" cicapModuleVersion="0.5.4"

RUN mkdir -p /tmp/install
RUN mkdir -p /opt/c-icap
RUN mkdir -p /var/log/c-icap/
RUN mkdir -p /run/clamav

WORKDIR /tmp/install

RUN	apk --update --no-cache add bzip2 bzip2-dev zlib zlib-dev curl tar gcc make g++ clamav clamav-libunrar

COPY c_icap-0.5.6.tar.gz .
COPY c_icap_modules-0.5.4.tar.gz .
COPY ./etc /opt/c-icap/etc
COPY ./opt/start.sh /
COPY custom_vir_sig.ndb /var/lib/clamav/ 

RUN tar -xzf "c_icap-${cicapBaseVersion}.tar.gz" && tar -xzf "c_icap_modules-${cicapModuleVersion}.tar.gz"

WORKDIR /tmp/install/c_icap-0.5.6

RUN ./configure --quiet --prefix=/opt/c-icap --enable-large-files && make && make install

WORKDIR /tmp/install/c_icap_modules-0.5.4
RUN ./configure --quiet --with-c-icap=/opt/c-icap --prefix=/opt/c-icap && make && make install

RUN	chown clamav:clamav /run/clamav
RUN sed -i 's/^#Foreground .*$/Foreground true/g' /etc/clamav/clamd.conf
RUN sed -i 's/^#Foreground .*$/Foreground true/g' /etc/clamav/freshclam.conf
RUN sed -i 's/#MaxAttempts .*$/MaxAttempts 5/g' /etc/clamav/freshclam.conf
RUN sed -i 's/#DatabaseMirror .*$/DatabaseMirror db.US.clamav.net/g' /etc/clamav/freshclam.conf

WORKDIR / 
RUN rm -rf /tmp/install
RUN apk del bzip2 bzip2-dev zlib zlib-dev curl tar gcc make g++
RUN chmod +x /start.sh
RUN sync
COPY entrypoint.sh /
RUN ls /opt

ENTRYPOINT [ "/entrypoint.sh" ]