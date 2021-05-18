# Base dev container on pre-existing image
FROM fabiankindermann/ce-fortran

# Install useful utilities and tools
RUN apt-get update && \
    apt-get -y install git

# Install and set fish as default shell
RUN apt-get -y install fish && chsh -s $(which fish)
