#!/usr/bin/env bash
# Graba capturas (JPG) y animaciones (WebP) de los dashboards para la guía
# de docs/dashboard/. Cada toma arma un kvim con su settings.dashboard (el
# mismo .wrap que usaría quien consume el flake), lo abre en ghostty y lo
# graba.
#
# Uso, desde la raíz del repo:
#   scripts/record-dashboards.sh            # todas las tomas
#   scripts/record-dashboards.sh doom hour  # solo esas
#
# Todo corre en un sway headless propio: nunca se abre una ventana en la
# sesión de sway del usuario (WAYLAND_DISPLAY se borra antes de arrancarlo).
# Grabar solo en thinkpad: ahí está la configuración de ghostty que muestra
# la galería, y los medios quedan iguales entre tomas.
set -euo pipefail

# Las herramientas vienen de nixpkgs sin instalarlas: el script se vuelve a
# llamar a sí mismo dentro de un nix shell si falta alguna.
tools=(sway ghostty grim wf-recorder ffmpeg)
for t in "${tools[@]}"; do
  if ! command -v "$t" >/dev/null; then
    exec nix shell nixpkgs#sway nixpkgs#ghostty nixpkgs#grim \
      nixpkgs#wf-recorder nixpkgs#ffmpeg -c "$0" "$@"
  fi
done

repo=$(git rev-parse --show-toplevel)
media="$repo/docs/dashboard/media"
work=$(mktemp -d)
mkdir -p "$media"

# kvim con un settings.dashboard dado. `nix build --impure --expr` porque
# la config es una expresión Nix, igual que en el flake de quien la usa.
build_kvim() {
  nix build --impure --no-link --print-out-paths --expr "
    let
      f = builtins.getFlake \"git+file://$repo\";
      pkgs = f.inputs.nixpkgs.legacyPackages.\${builtins.currentSystem};
    in
    f.wrappers.neovim.wrap [
      { inherit pkgs; }
      { settings.dashboard = $1; }
    ]"
}

# sway headless con salida fija: todas las tomas salen del mismo tamaño.
# 1600x1000 da unas 150 columnas en ghostty: los presets de dos columnas
# necesitan 130.
cat >"$work/sway.conf" <<'EOF'
output HEADLESS-1 resolution 1600x1000 scale 1
default_border none
default_floating_border none
gaps inner 0
bar {
  mode invisible
}
EOF

runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
before=$(find "$runtime" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' | sort)
(
  unset WAYLAND_DISPLAY DISPLAY SWAYSOCK
  WLR_BACKENDS=headless WLR_LIBINPUT_NO_DEVICES=1 exec sway -c "$work/sway.conf"
) >"$work/sway.log" 2>&1 &
sway_pid=$!
cleanup() {
  kill "$sway_pid" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

# El socket nuevo es el de este sway (el del usuario ya estaba).
for _ in $(seq 50); do
  after=$(find "$runtime" -maxdepth 1 -name 'wayland-*' ! -name '*.lock' | sort)
  sock=$(comm -13 <(echo "$before") <(echo "$after") | head -1)
  [ -n "$sock" ] && break
  sleep 0.1
done
[ -n "${sock:-}" ] || {
  echo "sway headless no arrancó" >&2
  cat "$work/sway.log" >&2
  exit 1
}
export WAYLAND_DISPLAY
WAYLAND_DISPLAY=$(basename "$sock")
unset DISPLAY

# Una toma: nombre, segundos de espera, segundos de video (0: solo foto),
# config del dashboard (Nix), y opcional un prefijo de entorno y argumentos
# extra para kvim.
shot() {
  local name=$1 wait=$2 secs=$3 dash=$4 env=${5:-} args=${6:-}
  if [ ${#only[@]} -gt 0 ] && [[ " ${only[*]} " != *" $name "* ]]; then
    return
  fi
  local kvim
  kvim=$(build_kvim "$dash")/bin/kvim
  # -n: sin swap file, así una toma cortada no traba la siguiente. Caché
  # vacío en cada toma: se ve lo mismo que en el primer arranque de quien
  # elige esa config (las salidas de comandos e imágenes todavía no están).
  ghostty --gtk-single-instance=false --window-decoration=false \
    --confirm-close-surface=false \
    -e bash -c "cd '$repo' && XDG_CACHE_HOME='$work/cache-$name' $env $kvim -n $args" >"$work/$name.log" 2>&1 &
  local gpid=$!
  sleep "$wait"
  if [ "$secs" -gt 0 ]; then
    wf-recorder -y -f "$work/$name.mp4" >/dev/null 2>&1 &
    local rpid=$!
    sleep "$secs"
    kill -INT "$rpid"
    wait "$rpid" 2>/dev/null || true
    # WebP animado: se ve en GitHub sin reproductor y pesa poco a 12 fps.
    ffmpeg -loglevel error -y -i "$work/$name.mp4" \
      -vf "fps=12,scale=720:-2" -loop 0 -c:v libwebp_anim -q:v 60 \
      "$media/$name.webp"
  else
    grim -t jpeg -q 85 "$media/$name.jpg"
  fi
  kill "$gpid" 2>/dev/null || true
  sleep 1
  echo "$name listo"
}

only=("$@")

# Presets: una línea de config cada uno.
for p in doom pokemon chafa startify advanced github compact image fastfetch calm ministarter; do
  shot "$p" 6 0 "{ preset = \"$p\"; }"
done
for p in blackhole bonsai aquarium; do
  shot "$p" 2 8 "{ preset = \"$p\"; }"
done

# Piezas sueltas que ningún preset muestra.
shot toilet 5 0 '{ preset = "doom"; header.kind = "toilet"; }'
shot shader 3 5 '{ preset = "doom"; header.kind = "shader"; }'
shot lolcat 2 6 '{ preset = "doom"; layout = "two"; panel = [ "lolcat" ]; }'
shot cmatrix 2 6 '{ preset = "doom"; layout = "two"; panel = [ "cmatrix" ]; }'

# Header según la hora. TZ mueve el reloj para ver el saludo de noche y el
# de mañana sin esperar: con TZ=UTCx la hora local es la de UTC menos x.
shot hour-night 5 0 '{ preset = "doom"; header.kind = "hour"; }' \
  "TZ=UTC$(($(date -u +%H) - 2))"
shot hour-morning 5 0 '{ preset = "doom"; header.kind = "hour"; }' \
  "TZ=UTC$(($(date -u +%H) - 9))"

# Splash del registro de milli: sale del input milli-splashes, sin red.
shot milli-aurora 2 5 '{ header.milli.splash = "aurora"; }'

# drop.nvim encima del dashboard de siempre.
shot drop-snow 2 7 '{ overlay.drop = { enable = true; theme = "snow"; }; }'

# Protector de pantalla: tres segundos sin tocar nada y aparece el shader.
shot screensaver 5 6 '{ extras.screensaver = { enable = true; after = 3; }; }'
