default: build

# Force env for server mods to be both
fix-envs:
    #!/usr/bin/env bash
    set -euxo pipefail
    
    rg -l 'side = "server"' \
      | xargs -i sed -Ei 's/^side = "server"/side = "both"/' '{}'

# Build the prism pack
prism:
    #!/usr/bin/env bash
    set -euxo pipefail

    set -a
        source .env
    set +a
    
    cd include/Prism

    envsubst \
        -no-unset -no-empty -fail-fast \
        -i ../unsup.ini.template \
        -o .minecraft/unsup.ini
    
    for file in *.template; do
        envsubst \
            -no-unset -no-empty -fail-fast \
            -i "$file" \
            -o "${file%.template}"
    done

    mv mmc-pack-${LOADER}.json mmc-pack.json
    rm mmc-pack-*.json
  
    zip -r Prism.zip * .minecraft -x '*.template'

    mv Prism.zip ../../build/Prism.zip
    rm .minecraft/unsup.ini

# Build the cf pack
curseforge:
    #!/usr/bin/env bash
    set -euxo pipefail

    set -a
        source .env
    set +a
    
    cp pack.toml include/Curseforge

    cd include/Curseforge
    touch index.toml

    wget 'https://git.sleeping.town/unascribed/unsup/releases/download/v0.2.3/unsup-0.2.3.jar' -O unsup.jar
    
    envsubst \
        -no-unset -no-empty -fail-fast \
        -i ../unsup.ini.template \
        -o ./unsup.ini

    packwiz refresh
    packwiz cf export -y -o ../../build/Curseforge.zip

# Build a profile for the vanilla launcher
launcher:
    #!/usr/bin/env bash
    set -euxo pipefail

    set -a
        source .env
    set +a
    
    envsubst \
        -no-unset -no-empty -fail-fast \
        -i include/Launcher/profile.json.template \
        -o build/profile.json
    
    envsubst \
        -no-unset -no-empty -fail-fast \
        -i include/unsup.ini.template \
        -o build/unsup.ini

    for script in install.command install.ps1; do
        cat "include/Launcher/$script" \
            | sed "s|%%repository%%|$REPOSITORY|g" \
            | tee "build/$script"
    done

# Clean old builds
clean:
    rm -rf build
    mkdir -p build

# Build all packs
build: clean fix-envs prism curseforge launcher
