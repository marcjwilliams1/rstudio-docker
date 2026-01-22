FROM bioconductor/bioconductor_docker:3.21

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

# Install CRAN packages in one layer
RUN Rscript -e "install.packages(c('argparse', 'R.utils', 'magick', 'devtools', 'optparse', 'phytools', 'languageserver', 'httpgd', 'tidyverse', 'quantreg', 'polynom', 'castor', 'caper', 'packrat', 'ggpubr', 'slider', 'mime', 'here', 'DT', 'dendextend', 'ismev', 'truncdist', 'extRemes', 'fitdistrplus', 'segmented', 'foreach', 'pastecs', 'doParallel', 'flexdashboard', 'pak'))" && \
    rm -rf /tmp/* /var/tmp/*

# Print bioconductor version
RUN Rscript -e "cat('Bioconductor version:', as.character(BiocManager::version()), '\n')"

# Install Bioconductor packages in one layer
RUN Rscript -e "BiocManager::install(c('QDNAseq', 'QDNAseq.hg19', 'BSgenome.Hsapiens.UCSC.hg38', 'BSgenome.Hsapiens.UCSC.hg19', 'SingleCellExperiment', 'escape', 'zellkonverter', 'rhdf5'))" && \
    rm -rf /tmp/* /var/tmp/*

# Check R can see the token
RUN Rscript -e "cat('R Environment GITHUB_PAT length:', nchar(Sys.getenv('GITHUB_PAT')), '\n'); if (nchar(Sys.getenv('GITHUB_PAT')) > 0) { cat('✓ GitHub token is available to R\n') } else { cat('✗ GitHub token is NOT available to R\n') }"

# Install GitHub R packages in one layer
ENV R_REMOTES_NO_ERRORS_FROM_WARNINGS=TRUE
RUN Rscript -e "library(devtools); \
    devtools::install_github('shahcompbio/signals', dependencies = TRUE); \
    devtools::install_github('caravagnalab/CNAqc', dependencies = TRUE); \
    devtools::install_github('broadinstitute/ichorCNA', dependencies = TRUE); \
    devtools::install_github('kevinmhadi/khtools', dependencies = TRUE); \
    devtools::install_github('mskilab-org/gGnome', dependencies = TRUE); \
    devtools::install_github('mskilab-org/GxG', dependencies = TRUE); \
    devtools::install_github('navinlabcode/copykat', dependencies = TRUE)" && \
    rm -rf /tmp/* /var/tmp/*

# Install anndataR, not yet on bioconductor
RUN Rscript -e "pak::pak('scverse/anndataR')" && \
    rm -rf /tmp/* /var/tmp/*

ADD policy.xml /etc/ImageMagick-6/policy.xml

# Samtools
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
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install radian system-wide
RUN pip3 install --no-cache-dir  --break-system-packages radian

# Install Miniforge (conda-forge focused) instead of Miniconda
RUN wget --quiet https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -O /tmp/miniforge.sh && \
    /bin/bash /tmp/miniforge.sh -b -p /opt/miniforge && \
    rm /tmp/miniforge.sh && \
    /opt/miniforge/bin/conda clean -a -y && \
    ln -s /opt/miniforge/etc/profile.d/conda.sh /etc/profile.d/conda.sh && \
    echo ". /opt/miniforge/etc/profile.d/conda.sh" >> ~/.bashrc

# Create environment and install packages
RUN /opt/miniforge/bin/mamba create -n scanpy_env python=3.10 -c conda-forge -y && \
    /opt/miniforge/bin/mamba install -n scanpy_env -c conda-forge -c bioconda \
    scanpy pandas numpy scipy matplotlib seaborn jupyter ipython \
    scikit-learn anndata leidenalg louvain scrublet harmonypy pysam \
    h5py mcp umap-learn python-igraph adjustText squidpy muon httpx pyreadr \
    scvi-tools decoupler-py rpy2 jupyterlab \
    -y && \
    /opt/miniforge/bin/conda clean -a -y && \
    rm -rf /root/.cache/*

# Install infercnvpy via pip
RUN /opt/miniforge/envs/scanpy_env/bin/pip install --no-cache-dir infercnvpy

# Set environment variables for reticulate and rpy2
ENV PATH=${PATH}:/opt/miniforge/envs/scanpy_env/bin
ENV RETICULATE_PYTHON=/opt/miniforge/envs/scanpy_env/bin/python
ENV R_HOME=/usr/local/lib/R

# Install reticulate and other useful R packages
RUN R -e "install.packages(c('reticulate', 'Seurat', 'SingleCellExperiment'), repos='https://cloud.r-project.org/')" && \
    rm -rf /tmp/* /var/tmp/*

# Configure reticulate to use the conda environment
RUN R -e "library(reticulate); use_condaenv('scanpy_env', conda='/opt/miniforge/bin/conda')"

ENV PATH=${PATH}:/usr/src/samtools-1.9

# Clean up GitHub token
RUN sed -i '/GITHUB_PAT/d' /usr/local/lib/R/etc/Renviron.site
ENV GITHUB_PAT=

WORKDIR /usr/src
