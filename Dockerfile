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
# Check R can see the token
RUN Rscript -e "cat('R Environment GITHUB_PAT length:', nchar(Sys.getenv('GITHUB_PAT')), '\n'); if (nchar(Sys.getenv('GITHUB_PAT')) > 0) { cat('✓ GitHub token is available to R\n') } else { cat('✗ GitHub token is NOT available to R\n') }"

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
    curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Miniforge (conda-forge focused) instead of Miniconda
RUN wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh && \
    /bin/bash /tmp/miniforge.sh -b -p /opt/miniforge && \
    rm /tmp/miniforge.sh && \
    /opt/miniforge/bin/conda clean -a -y && \
    ln -s /opt/miniforge/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/miniforge/etc/profile.d/conda.sh" >> ~/.bashrc

# Create conda environment with scanpy using conda-forge
RUN /opt/miniforge/bin/conda create -n scanpy_env python=3.12 -c conda-forge -y && \
    /opt/miniforge/bin/conda install -n scanpy_env -c conda-forge -c bioconda \
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
    mcp \
    httpx \
    scrublet \          
    scvi-tools \       
    harmonypy \         
    pysam \            
    h5py \              
    umap-learn \        
    python-igraph \     
    adjustText \        
    squidpy \           
    muon \             
    decoupler-py \      
    pyreadr \           
    infercnvpy \        
    -y && \
    /opt/miniforge/bin/conda clean -a -y

# Set environment variables for reticulate
ENV RETICULATE_PYTHON=/opt/miniforge/envs/scanpy_env/bin/python
ENV PATH=/opt/miniforge/envs/scanpy_env/bin:$PATH

# Install reticulate and other useful R packages
RUN R -e "install.packages(c('reticulate', 'Seurat', 'SingleCellExperiment'), repos='https://cloud.r-project.org/')"

# Configure reticulate to use the conda environment
RUN R -e "library(reticulate); use_condaenv('scanpy_env', conda='/opt/miniforge/bin/conda')"

ENV PATH=${PATH}:/usr/src/samtools-1.9

# Clean up GitHub token
RUN sed -i '/GITHUB_PAT/d' /usr/local/lib/R/etc/Renviron.site
ENV GITHUB_PAT=

WORKDIR /usr/src
