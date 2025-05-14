#!/bin/bash

source /venv/main/bin/activate
FORGE_DIR=${WORKSPACE}/stable-diffusion-webui-forge

# Packages are installed after nodes so we can fix them...

APT_PACKAGES=(
)

PIP_PACKAGES=(

)

CHECKPOINT_MODELS=(
    "https://civitai.com/api/download/models/290640?type=Model&format=SafeTensor&size=pruned&fp=fp16 /workspace/stable-diffusion-webui-forge/models/Stable-diffusion/pony.safetensors"
)

UNET_MODELS=(
)

LORA_MODELS=(
    "https://civitai.com/api/download/models/382152?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/expressive_h.safetensors"
    "https://civitai.com/api/download/models/333607?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/smooth_anime.safetensors"
    "https://civitai.com/api/download/models/436219?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/incase.safetensors"
    "https://civitai.com/api/download/models/373076?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/vintage.safetensors"
    "https://civitai.com/api/download/models/767078?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/pov_instant_loss.safetensors"
    "https://civitai.com/api/download/models/406664?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/instant_loss_2koma.safetensors"
    "https://civitai.com/api/download/models/1122823?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/morimee_style.safetensors"
    "https://civitai.com/api/download/models/381063?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/asura_style.safetensors"
    "https://civitai.com/api/download/models/359222?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/thick_penis.safetensors"
    "https://civitai.com/api/download/models/1029540?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/gothic_neon.safetensors"
    "https://civitai.com/api/download/models/433657?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/gravs_transformation.safetensors"
    "https://civitai.com/api/download/models/517898?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/penis_size_slider.safetensors"
    "https://civitai.com/api/download/models/796189?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/Lora/palm_sized_girl.safetensors"
    "https://civitai.com/api/download/models/287973?type=Model&format=SafeTensor /workspace/stable-diffusion-webui-forge/embeddings/SimpleNegativeV3.safetensors"
    "https://files.catbox.moe/kbaz4k.safetensors /workspace/stable-diffusion-webui-forge/models/Lora/trogfor_toon.safetensors"
    "https://files.catbox.moe/ojbvr4.safetensors /workspace/stable-diffusion-webui-forge/models/Lora/afrobull_toon.safetensors"
    "https://files.catbox.moe/y5xajf.safetensors /workspace/stable-diffusion-webui-forge/models/Lora/asashina_toon.safetensors"
    "https://files.catbox.moe/odmswn.safetensors /workspace/stable-diffusion-webui-forge/models/Lora/fkey_hd.safetensors"
    "https://files.catbox.moe/ma4ly2.safetensors /workspace/stable-diffusion-webui-forge/models/Lora/monstrousfrog_toon.safetensors"
)

VAE_MODELS=(
    "https://civitai.com/api/download/models/290640?type=VAE&format=SafeTensor /workspace/stable-diffusion-webui-forge/models/VAE/pony.safetensors"
)

ESRGAN_MODELS=(
)

CONTROLNET_MODELS=(
)

### DO NOT EDIT BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING ###

function provisioning_start() {
    provisioning_print_header
    provisioning_get_apt_packages
    provisioning_get_extensions
    provisioning_get_pip_packages
    provisioning_get_files \
        "${FORGE_DIR}/models/Stable-diffusion" \
        "${CHECKPOINT_MODELS[@]}"

    # Avoid git errors because we run as root but files are owned by 'user'
    export GIT_CONFIG_GLOBAL=/tmp/temporary-git-config
    git config --file $GIT_CONFIG_GLOBAL --add safe.directory '*'
    
    # Start and exit because webui will probably require a restart
    cd "${FORGE_DIR}"
    LD_PRELOAD=libtcmalloc_minimal.so.4 \
        python launch.py \
            --skip-python-version-check \
            --no-download-sd-model \
            --do-not-download-clip \
            --no-half \
            --port 11404 \
            --exit

    provisioning_print_end
}

function provisioning_get_apt_packages() {
    if [[ -n $APT_PACKAGES ]]; then
            sudo $APT_INSTALL ${APT_PACKAGES[@]}
    fi
}

function provisioning_get_pip_packages() {
    if [[ -n $PIP_PACKAGES ]]; then
            pip install --no-cache-dir ${PIP_PACKAGES[@]}
    fi
}

function provisioning_get_extensions() {
    for repo in "${EXTENSIONS[@]}"; do
        dir="${repo##*/}"
        path="${FORGE_DIR}/extensions/${dir}"
        if [[ ! -d $path ]]; then
            printf "Downloading extension: %s...\n" "${repo}"
            git clone "${repo}" "${path}" --recursive
        fi
    done
}

function provisioning_get_files() {
    if [[ -z $2 ]]; then return 1; fi
    
    dir="$1"
    mkdir -p "$dir"
    shift
    arr=("$@")
    printf "Downloading %s model(s) to %s...\n" "${#arr[@]}" "$dir"
    for url in "${arr[@]}"; do
        printf "Downloading: %s\n" "${url}"
        provisioning_download "${url}" "${dir}"
        printf "\n"
    done
}

function provisioning_print_header() {
    printf "\n##############################################\n#                                            #\n#          Provisioning container            #\n#                                            #\n#         This will take some time           #\n#                                            #\n# Your container will be ready on completion #\n#                                            #\n##############################################\n\n"
}

function provisioning_print_end() {
    printf "\nProvisioning complete:  Application will start now\n\n"
}

function provisioning_has_valid_hf_token() {
    [[ -n "$HF_TOKEN" ]] || return 1
    url="https://huggingface.co/api/whoami-v2"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $HF_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

function provisioning_has_valid_civitai_token() {
    [[ -n "$CIVITAI_TOKEN" ]] || return 1
    url="https://civitai.com/api/v1/models?hidden=1&limit=1"

    response=$(curl -o /dev/null -s -w "%{http_code}" -X GET "$url" \
        -H "Authorization: Bearer $CIVITAI_TOKEN" \
        -H "Content-Type: application/json")

    # Check if the token is valid
    if [ "$response" -eq 200 ]; then
        return 0
    else
        return 1
    fi
}

# Download from $1 URL to $2 file path
function provisioning_download() {
    if [[ -n $HF_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?huggingface\.co(/|$|\?) ]]; then
        auth_token="$HF_TOKEN"
    elif 
        [[ -n $CIVITAI_TOKEN && $1 =~ ^https://([a-zA-Z0-9_-]+\.)?civitai\.com(/|$|\?) ]]; then
        auth_token="$CIVITAI_TOKEN"
    fi
    if [[ -n $auth_token ]];then
        wget --header="Authorization: Bearer $auth_token" -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    else
        wget -qnc --content-disposition --show-progress -e dotbytes="${3:-4M}" -P "$2" "$1"
    fi
}

# Allow user to disable provisioning if they started with a script they didn't want
if [[ ! -f /.noprovisioning ]]; then
    provisioning_start
fi
