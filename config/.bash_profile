# # Change the value for FSLDIR if you have 
# # installed FSL into a different location
# FSLDIR=/usr/local/fsl
# . ${FSLDIR}/etc/fslconf/fsl.sh
# PATH=${FSLDIR}/bin:${PATH}
# export FSLDIR PATH

# LC_NUMERIC=en_GB.UTF-8
# export LC_NUMERIC

#only execute if ghostfs is mounted
if mount |grep -q GhostFS
then
    #FreeSurfer
    # Change the value for FREESURFER_HOME if you have 
    # installed Freesurfer into a different location
    APP_VERSION=$(ls /usr/local/freesurfer/)

    # Create a license file
    if [ -s "$HOME/run.env" ]; then
        echo "Loading license from $HOME/run.env"
        . "$HOME/run.env"
    else
        echo "No license file found in $HOME/run.env"
    fi

    echo -e "$FREESURFER_LICENSE" > "$HOME/license.txt"

    export FREESURFER_HOME=/usr/local/freesurfer/${APP_VERSION}
    export FS_LICENSE=$HOME/license.txt

    #mkdir -p $HOME/nextcloud/data/freesurfer_subjects
    #export SUBJECTS_DIR=$HOME/nextcloud/data/freesurfer_subjects
    mkdir -p $HOME/data/freesurfer_subjects
    export SUBJECTS_DIR=$HOME/data/freesurfer_subjects

    source $FREESURFER_HOME/SetUpFreeSurfer.sh

    
    # Change the value for FSLDIR if you have 
    # installed FSL into a different location
    FSLDIR=/usr/local/fsl
    . ${FSLDIR}/etc/fslconf/fsl.sh
    PATH=${FSLDIR}/bin:${PATH}
    export FSLDIR PATH

    LC_NUMERIC=en_GB.UTF-8
    export LC_NUMERIC
fi

# Load the default .profile
[[ -s "$HOME/.profile" ]] && source "$HOME/.profile"
