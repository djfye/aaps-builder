FROM alpine:edge

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

# Install packages
RUN rm -rf /etc/apk/repositories
RUN echo 'https://dl-cdn.alpinelinux.org/alpine/edge/main' >> /etc/apk/repositories
RUN echo 'https://dl-cdn.alpinelinux.org/alpine/edge/community' >> /etc/apk/repositories
RUN echo 'https://dl-cdn.alpinelinux.org/alpine/edge/testing' >> /etc/apk/repositories
RUN apk update
RUN apk add --no-cache tzdata curl binutils zstd gcompat libstdc++ openjdk23 bash nano git unzip wget apache2

# Set variables
ENV JAVA_HOME=/usr/lib/jvm/default-jvm PATH=/usr/lib/jvm/default-jvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV ANDROID_SDK_ROOT=/opt/sdk
ENV ANDROID_HOME=/opt/sdk
ENV CMDLINE_VERSION=19.0
ENV SDK_TOOLS=13114758
ENV PATH=/usr/lib/jvm/default-jvm/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/sdk/cmdline-tools/${CMDLINE_VERSION}/bin:/opt/sdk/platform-tools:/opt/sdk/extras/google/instantapps
ENV WAITTIME=60
ENV PUID=99
ENV PGID=100
RUN -u ${PUID}:${PGID}

# Install android studio components
RUN rm -rf /tmp/*
RUN rm -rf /var/cache/apk/*
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-${SDK_TOOLS}_latest.zip -O /tmp/tools.zip
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools
RUN unzip -qq /tmp/tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools
RUN mv ${ANDROID_SDK_ROOT}/cmdline-tools/* ${ANDROID_SDK_ROOT}/cmdline-tools/${CMDLINE_VERSION}
RUN rm -v /tmp/tools.zip
RUN mkdir -p ~/.android/
RUN touch ~/.android/repositories.cfg
RUN yes | sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --licenses
RUN sdkmanager --sdk_root=${ANDROID_SDK_ROOT} --install "platform-tools" "extras;google;instantapps"

# Set keystore data
COPY extras /bin
WORKDIR /home/android
ENV KEYSTORE_FILE=keystore
ENV KEYSTORE_PASSWORD=AndroidAPS
ENV KEYSTORE_ALIAS=key0
ENV VERSION=master

# Copy build script
VOLUME [/home/aaps]
WORKDIR /home/aaps
COPY build-aaps /usr/bin
RUN chmod +x /usr/bin/build-aaps
COPY patches /tmp/patches/

# Setup web server
RUN rm -rf /var/www/localhost/htdocs
RUN ln -s -f /home/aaps/apk/ /var/www/localhost/htdocs
RUN sed -i 's/Listen 80/Listen 8080/g' /etc/apache2/httpd.conf
EXPOSE 8080

# Run build script
ENTRYPOINT build-aaps
