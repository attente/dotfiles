FROM znc

RUN apk add git curl-dev
RUN git clone https://github.com/jreese/znc-push.git
RUN CXXFLAGS="$CXXFLAGS -DUSE_CURL" LIBS="$LIBS -lcurl" /opt/znc/bin/znc-buildmod /znc-push/push.cpp
RUN mkdir -p /root/.znc/modules
RUN mv push.so /root/.znc/modules

ENTRYPOINT ["sh", "-c", "mkdir -p /znc-data/modules && cp -rf /root/.znc/modules/* /znc-data/modules && /entrypoint.sh"]
