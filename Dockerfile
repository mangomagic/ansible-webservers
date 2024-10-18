FROM ansible-environment

# Update package list and install necessary packages
RUN apt-get update && \
    apt-get install -y \
    vim \
    curl \
    ansible \
    nginx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/entrypoint.sh /usr/bin

CMD [ "/usr/bin/entrypoint.sh" ]