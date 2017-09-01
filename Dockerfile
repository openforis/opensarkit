FROM ubuntu:xenial

MAINTAINER Andreas Vollrath "andreas.vollrath@fao.org"

EXPOSE 3838

# system libraries of general use
RUN apt-get update && apt-get install -y \
    software-properties-common \
    sudo \
    nano \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libssl1.0.0 \
    wget \
    lsb-release

ADD bins/Install_OST/installer_ubuntu1604.sh /usr/local/bin/installer_ubuntu1604.sh

RUN cd /usr/local/bin/ && bash ./installer_ubuntu1604.sh /usr/local/lib/ost yes

RUN echo 'local({options(shiny.port = 3838, shiny.host = "0.0.0.0")})' >> /usr/lib/R/etc/Rprofile.site
#RUN while read line; do echo "export $line" | tee -a /root/.bashrc; done </etc/environment;
RUN cp /etc/environment /etc/R/Renviron.site

RUN echo '. /root/.bashrc' \
  >> /usr/local/lib/ost/opensarkit/start_shiny.sh && \
 echo 'R -e shiny::runApp\(\"/usr/local/lib/ost/opensarkit/shiny\"\)' \
  >> /usr/local/lib/ost/opensarkit/start_shiny.sh && \
  chmod +x /usr/local/lib/ost/opensarkit/start_shiny.sh

CMD ["bash", "-c", "source /etc/environment; R -e \"shiny::runApp('/usr/local/lib/ost/opensarkit/shiny')\""]

#CMD ["bash", "-c", "/usr/local/lib/ost/opensarkit/start_shiny.sh"]
