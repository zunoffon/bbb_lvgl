FROM scratch

ARG http_proxy
ARG https_proxy

ARG user=user
ARG group=${user}
ARG uid=1000
ARG gid=${uid}

ADD ospack_v2022-amd64-sdk_v2022.4.tar.gz /

RUN if [ "$http_proxy" ]; then printf 'Acquire::http::Proxy    "%s";\n' "$http_proxy" >/etc/apt/apt.conf.d/99-apt-http-proxy; fi
RUN if [ "$https_proxy" ]; then printf 'Acquire::https::Proxy    "%s";\n' "$https_proxy" >/etc/apt/apt.conf.d/99-apt-https-proxy; fi

RUN sudo dpkg --add-architecture armhf
RUN apt-get update
RUN apt-get install -y build-essential libncurses-dev bison flex bc lzop libssl-dev libelf-dev

RUN if [ "x$group" = "xuser" ]; then :; elif [ "$(getent group user | cut -d: -f3)" = $gid ]; then groupmod -n $group user; else groupadd -o -g ${gid} ${group}; fi
RUN if [ "x$user" = "xuser" ]; then :; elif [ "$(getent passwd user | cut -d: -f3)" = $uid ]; then usermod -m -d /home/$user -g $gid -G root,sudo,admin -s /bin/bash -l $user user; else useradd -l -m -o -u ${uid} -g ${group} -G root,sudo -s /bin/bash ${user}; fi
RUN printf "%s ALL=(ALL) NOPASSWD: ALL\\n" user "$user" >/etc/sudoers.d/00-nopasswd
RUN mkdir -p -m0700 /home/$user
RUN chown $user:$group /home/$user
USER $user
RUN cp -r /etc/skel/.[a-z]* /home/$user/
RUN sed -i '/force_color_prompt=/s/#//;/PS1=/s/u@/u@docker./' /home/$user/.bashrc

CMD ["/bin/bash"]
