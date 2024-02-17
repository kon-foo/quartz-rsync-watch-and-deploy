FROM node:20-slim
RUN apt-get update && \
    apt-get install -y inotify-tools rsync git && \
    rm -rf /var/lib/apt/lists/*
RUN git clone https://github.com/jackyzha0/quartz /quartz
WORKDIR /quartz
RUN npm ci
COPY watch.sh .
CMD ["./watch.sh"]