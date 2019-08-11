FROM google/cloud-sdk
MAINTAINER Alvaro Miranda <kikitux@gmail.com>

COPY run-builder.sh /bin
CMD ["bash", "-xe", "/bin/run-builder.sh"]
