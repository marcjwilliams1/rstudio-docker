FROM bioconductor/bioconductor_docker

RUN --mount=type=secret,id=github_token \
  export GITHUB_PAT=$(cat /run/secrets/github_token) 

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

# Install system dependencies for Python and scientific computing
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-dev \
    python3-venv \
    build-essential \
    libhdf5-dev \
    libxml2-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda for better Python package management
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p /opt/miniconda && \
    rm /tmp/miniconda.sh && \
    /opt/miniconda/bin/conda clean -tipsy && \
    ln -s /opt/miniconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/miniconda/etc/profile.d/conda.sh" >> ~/.bashrc

# Create conda environment with scanpy and related tools
RUN /opt/miniconda/bin/conda create -n scanpy_env python=3.9 -y && \
    /opt/miniconda/bin/conda install -n scanpy_env -c conda-forge -c bioconda \
    scanpy \
    pandas \
    numpy \
    scipy \
    matplotlib \
    seaborn \
    jupyter \
    ipython \
    scikit-learn \
    anndata \
    leidenalg \
    louvain \
    -y && \
    /opt/miniconda/bin/conda clean -all

# Set environment variables for reticulate
ENV RETICULATE_PYTHON=/opt/miniconda/envs/scanpy_env/bin/python
ENV PATH=/opt/miniconda/envs/scanpy_env/bin:$PATH

# Install reticulate and other useful R packages
RUN R -e "install.packages(c('reticulate', 'Seurat', 'SingleCellExperiment'), repos='https://cloud.r-project.org/')"

# Configure reticulate to use the conda environment
RUN R -e "library(reticulate); use_condaenv('scanpy_env', conda='/opt/miniconda/bin/conda')"

WORKDIR /usr/src
