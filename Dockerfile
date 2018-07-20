FROM alpine:3.7
#FROM fedora:24

RUN mkdir -p /home/armada-storage/
RUN mkdir -p /host
ADD images/systemutil /home/armada-storage
ADD images/iscsi-attach.sh /home/armada-storage
ADD images/iscsi-portworx-volume.conf /home/armada-storage
ADD images/ibmc-portworx.service /home/armada-storage
ADD images/run.sh /home/armada-storage
RUN chmod 775 /home/armada-storage/systemutil
RUN chmod 775 /home/armada-storage/run.sh
RUN chmod 775 /home/armada-storage/iscsi-attach.sh

COPY armada-px-integration /home/armada-storage
RUN chmod +x /home/armada-storage/armada-px-integration

CMD ./home/armada-storage/run.sh
#ENTRYPOINT ["/home/armada-storage/armada-px-integration"]
