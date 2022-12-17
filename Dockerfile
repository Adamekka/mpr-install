FROM ubuntu:latest

WORKDIR /mpr/
RUN echo "\033[0;31mcd mpr done\033[0m"

RUN apt update
RUN apt install make curl git jq wget gpg iputils-ping sudo apt-utils -y
RUN echo "\033[0;31mapt done\033[0m"

RUN wget -qO - 'https://proget.makedeb.org/debian-feeds/makedeb.pub' | gpg --dearmor | tee /usr/share/keyrings/makedeb-archive-keyring.gpg 1> /dev/null
RUN echo 'deb [signed-by=/usr/share/keyrings/makedeb-archive-keyring.gpg arch=all] https://proget.makedeb.org/ makedeb main' | tee /etc/apt/sources.list.d/makedeb.list
RUN apt update
RUN apt install makedeb -y
# RUN export MAKEDEB_RELEAE='makedeb'
# RUN export TERM='docker'
# RUN bash -c "$(wget -O - 'https://shlink.makedeb.org/install')"
RUN echo "\033[0;31mmakedeb done\033[0m"

COPY ./mpr.sh /mpr/mpr.sh
COPY ./Makefile /mpr/Makefile
RUN echo "\033[0;31mcopy done\033[0m"

RUN make install
RUN echo "\033[0;31minstall done\033[0m"

RUN groupadd wheel
RUN echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
RUN useradd -ms /bin/bash -g wheel user; echo "user:password" | chpasswd
RUN echo "\033[0;31mcreate user done\033[0m"
