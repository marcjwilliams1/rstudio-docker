FROM bioconductor/bioconductor_docker

ARG GITHUB_PAT
ENV GITHUB_PAT=$GITHUB_PAT

# Debug: Check if token is available and working
RUN echo "Checking GitHub token setup..." && \
    if [ -z "$GITHUB_PAT" ]; then \
      echo "WARNING: GITHUB_PAT is not set" \
    ; else \
      echo "GITHUB_PAT is set (length: ${#GITHUB_PAT})" && \
      echo "Testing GitHub API access..." && \
      curl -s -H "Authorization: token $GITHUB_PAT" \
           https://api.github.com/rate_limit | head -10 \
    ; fi

# Configure R to use the token
RUN if [ ! -z "$GITHUB_PAT" ]; then \
      echo "GITHUB_PAT=${GITHUB_PAT}" >> /usr/local/lib/R/etc/Renviron.site \
    ; fi

RUN apt-get update && apt-get -y upgrade && \
        apt-get install -y build-essential wget \
                libncurses5-dev zlib1g-dev libbz2-dev liblzma-dev libcurl3-dev libcairo2-dev libxt-dev xclip xvfb && \
        apt-get clean && apt-get purge && \
        rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN Rscript -e "install.packages('argparse')"
RUN Rscript -e "install.packages('R.utils')"
RUN Rscript -e "install.packages('magick')"
RUN Rscript -e "install.packages('devtools')"
RUN Rscript -e "install.packages('optparse')"
RUN Rscript -e "install.packages('phytools')"
RUN Rscript -e "install.packages('tidyverse')"
RUN Rscript -e "install.packages('quantreg')"
RUN Rscript -e "install.packages('polynom')"
RUN Rscript -e "install.packages('castor')"
RUN Rscript -e "install.packages('caper')"
RUN Rscript -e "install.packages('packrat')"
RUN Rscript -e "install.packages('ggpubr')"
RUN Rscript -e "install.packages('slider')"
RUN Rscript -e "install.packages('mime')"
RUN Rscript -e "install.packages('here')"
RUN Rscript -e "install.packages('DT')"
RUN Rscript -e "install.packages('dendextend')"
RUN Rscript -e "install.packages('ismev')"
RUN Rscript -e "install.packages('truncdist')"
RUN Rscript -e "install.packages('extRemes')"
RUN Rscript -e "install.packages('fitdistrplus')"
RUN Rscript -e "install.packages('segmented')"
RUN Rscript -e "install.packages('foreach')"
RUN Rscript -e "install.packages('pastecs')"
RUN Rscript -e "install.packages('doParallel')"
RUN Rscript -e "install.packages('flexdashboard')"
RUN Rscript -e "BiocManager::install('QDNAseq')"
RUN Rscript -e "BiocManager::install('QDNAseq.hg19')"
RUN Rscript -e "BiocManager::install('BSgenome.Hsapiens.UCSC.hg38.masked')"
RUN Rscript -e "BiocManager::install('BSgenome.Hsapiens.UCSC.hg38')"
RUN Rscript -e "BiocManager::install('BSgenome.Hsapiens.UCSC.hg19.masked')"
RUN Rscript -e "BiocManager::install('BSgenome.Hsapiens.UCSC.hg19')"
RUN Rscript -e "BiocManager::install('SingleCellExperiment')"
RUN Rscript -e "BiocManager::install('escape')"
RUN Rscript -e "BiocManager::install('zellkonverter')"
RUN Rscript -e "BiocManager::install('rhdf5')"
RUN Rscript -e "BiocManager::install('anndataR')"

# Check R can see github token the token
RUN Rscript -e "
  cat('R Environment GITHUB_PAT length:', nchar(Sys.getenv('GITHUB_PAT')), '\n')
  if (nchar(Sys.getenv('GITHUB_PAT')) > 0) {
    cat('✓ GitHub token is available to R\n')
  } else {
    cat('✗ GitHub token is NOT available to R\n')
  }
"

RUN Rscript -e "library(devtools)"
RUN Rscript -e "devtools::install_github('shahcompbio/signals', dependencies = TRUE)"
RUN Rscript -e "devtools::install_github('caravagnalab/CNAqc', dependencies = TRUE)"
RUN Rscript -e "devtools::install_github('broadinstitute/ichorCNA', dependencies = TRUE)"

ADD policy.xml /etc/ImageMagick-6/policy.xml

#Samtools
RUN wget https://github.com/samtools/samtools/releases/download/1.9/samtools-1.9.tar.bz2 && \
        tar jxf samtools-1.9.tar.bz2 && \
        rm samtools-1.9.tar.bz2 && \
        cd samtools-1.9 && \
        ./configure --prefix $(pwd) && \
        make

ENV PATH=${PATH}:/usr/src/samtools-1.9

WORKDIR /usr/src
