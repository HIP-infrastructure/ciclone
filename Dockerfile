ARG CI_REGISTRY_IMAGE
ARG TAG
ARG DOCKERFS_TYPE
ARG DOCKERFS_VERSION
FROM ${CI_REGISTRY_IMAGE}/${DOCKERFS_TYPE}:${DOCKERFS_VERSION}${TAG}
LABEL maintainer="florian.sipp@chuv.ch"

ARG DEBIAN_FRONTEND=noninteractive
ARG CARD
ARG CI_REGISTRY
ARG APP_NAME
ARG APP_VERSION

LABEL app_version=$APP_VERSION
LABEL app_tag=$TAG

WORKDIR /apps/${APP_NAME}

# Step 1 : Install Freesurfer
ARG FREESURFER_VERSION=8.0.0
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
    curl language-pack-en binutils \
    libx11-dev gettext xterm x11-apps perl \
    make csh tcsh file bc xorg xorg-dev \
    xserver-xorg-video-intel libncurses5 \
    libgomp1 libjpeg62 libpcre2-16-0 libquadmath0 \
    libxcb-icccm4 libxcb-render-util0 libxcb-render0 \
    libxcb-shape0 libxcb-xinerama0 libxcb-xinput0 \
    libxft2 libxi6 libxrender1 libxss1 && \
    curl -sSO https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/${FREESURFER_VERSION}/freesurfer_ubuntu22-${FREESURFER_VERSION}_amd64.deb && \
    dpkg -i freesurfer_ubuntu22-${FREESURFER_VERSION}_amd64.deb && \
    rm freesurfer_ubuntu22-${FREESURFER_VERSION}_amd64.deb && \
    apt-get remove -y --purge curl && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Step 2 : Install FSL
# The sed expression is silencing `printmsg` calls with end=\r that are causing
# a lot of logs to be outputted. They don't play well with GitLab (and other CI
# in general).
ARG FSL_VERSION=6.0.7.17
ADD https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/fslinstaller.py .
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \
        ca-certificates \
        tar \
        bzip2 \
        dc \
        file \
        libgomp1 \
        libquadmath0 \
        locales \
        python3 && \
    locale-gen en_US.UTF-8 en_GB.UTF-8 && \
    sed -i -E "s/(printmsg\(([^,]+, )?end='(\\\\r)?')/# SILENCE \\1/g" ./fslinstaller.py && \
    python3 ./fslinstaller.py \
        -d /usr/local/fsl \
        -V ${FSL_VERSION} \
        --skip_registration \
        --no_self_update && \
    rm -rf /usr/local/fsl/src && \
    rm fslinstaller.py && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Step 3 : Install CiCLONEe
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install --no-install-recommends -y \ 
    git python3 python3-pip python3-venv \
    libxcb-cursor0 && \
    python3 -m venv /apps/${APP_NAME}/venv && \
    . /apps/${APP_NAME}/venv/bin/activate && \
    pip install --no-cache git+https://github.com/floriansipp/CiCLONE/@v${APP_VERSION}#egg=CiCLONE && \
    chmod 644 /apps/${APP_NAME}/venv/lib/python3.10/site-packages/${APP_NAME}/config/*.yaml && \
    chmod -R 755 /apps/${APP_NAME}/venv/lib/python3.10/site-packages/${APP_NAME}/config/electrodes && \
    apt-get remove -y --purge git && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# MESA_GL_VERSION_OVERRIDE is needed to be able to launch fsl as a subprocess in the container
ENV MESA_GL_VERSION_OVERRIDE=3.3

ENV APP_NAME=${APP_NAME}
ENV APP_SPECIAL="no"
ENV APP_CMD="ciclone"
ENV PROCESS_NAME="ciclone"
ENV APP_DATA_DIR_ARRAY=""
ENV DATA_DIR_ARRAY=""
ENV CONFIG_ARRAY=".bash_profile"

HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

COPY ./scripts/ scripts/
COPY ./apps/${APP_NAME}/config config/

ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
