FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    openssh-server \
    sudo \
    nginx \
    python3-apt \
    vim \
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create mangomagic user with passwordless sudo
RUN useradd -m -s /bin/bash mangomagic && \
    echo 'mangomagic ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/mangomagic && \
    mkdir -p /home/mangomagic/.ssh && \
    chmod 700 /home/mangomagic/.ssh && \
    chown -R mangomagic:mangomagic /home/mangomagic/.ssh

# Prepare sshd runtime directory
RUN mkdir -p /run/sshd

COPY scripts/entrypoint.sh /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

EXPOSE 22 80 443

CMD ["/usr/bin/entrypoint.sh"]
