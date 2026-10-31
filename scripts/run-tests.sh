#!/usr/bin/env bash
#
# Pré-vol avant de lancer UN test Playwright précis (à exécuter depuis Git Bash) :
#   Étape 1 — Node / npm présents
#   Étape 2 — dépendances npm installées
#   Étape 3 — CLI Playwright opérationnelle
#   Étape 4 — navigateurs Playwright installés (au moins chromium)
# Puis lance ce SEUL test avec `playwright test <spec> --project=chromium`.
#
# Usage : ./scripts/run-tests.sh -h

set -uo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR" || exit 1

BROWSER_CACHE="${LOCALAPPDATA:-$HOME}/ms-playwright"
TOTAL_STEPS=4

# --- Couleurs -----------------------------------------------------------
# quoting ANSI-C ($'...') : les variables contiennent le vrai octet ESC, donc
# un simple `echo` les affiche déjà correctement (pas besoin de `echo -e`).
# IMPORTANT : ne JAMAIS utiliser `echo -e` sur une ligne qui affiche un
# chemin Windows (ex: C:\Users\...) — `-e` interprète "\a", "\n", "\t"...
# comme des séquences d'échappement et corrompt le chemin (ex: "\aganh"
# devient juste "ganh", le \a étant lu comme le caractère BEL).
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[0;33m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
RESET=$'\033[0m'

OK="${GREEN}✔${RESET}"
KO="${RED}✖${RESET}"
WARN="${YELLOW}⚠${RESET}"

# --- Fonctions utilitaires ---------------------------------------------

die() {
    echo "" >&2
    echo "${KO} ${RED}$1${RESET}" >&2
    exit 1
}

step_header() {
    echo ""
    echo "${BOLD}${CYAN}── Étape $1/${TOTAL_STEPS} : $2${RESET}"
}

list_specs() {
    local found
    found="$(find "$ROOT_DIR/specs" -type f -name '*.spec.ts' 2>/dev/null | sed "s#^$ROOT_DIR/##")"
    if [ -z "$found" ]; then
        echo "  (aucun spec pour l'instant dans specs/)"
    else
        echo "$found" | sed 's/^/  - /'
    fi
}

show_help() {
    cat <<EOF
${BOLD}Usage${RESET} : ./scripts/run-tests.sh [-h|--help] <nom-du-test> [options playwright...]

Vérifie que l'environnement Playwright est prêt (4 étapes), puis lance UN
SEUL fichier de test — jamais toute la suite d'un coup.

${BOLD}Arguments${RESET}
  <nom-du-test>   Nom ou chemin du spec à lancer. Accepte :
                    - un nom partiel      : login
                    - un nom de fichier    : login.spec.ts
                    - un chemin complet    : specs/login.spec.ts

${BOLD}Options${RESET}
  -h, --help      Affiche cette aide et quitte (aucune vérification lancée)

Tout argument supplémentaire après le nom du test est transmis tel quel à
"playwright test" (ex: --project=firefox, --headed, --debug).

${BOLD}Exemples${RESET}
  ./scripts/run-tests.sh login
  ./scripts/run-tests.sh login --headed
  ./scripts/run-tests.sh login --project=firefox

${BOLD}Specs disponibles${RESET}
$(list_specs)
EOF
}

# Résout un nom/chemin de test vers un chemin de spec réel.
# Écrit le chemin trouvé sur stdout. Code retour : 0 trouvé, 1 introuvable,
# 2 ambigu (plusieurs correspondances, listées sur stderr).
resolve_spec() {
    local query="$1"

    if [ -f "$ROOT_DIR/$query" ]; then
        printf '%s\n' "$query"
        return 0
    fi
    if [ -f "$ROOT_DIR/specs/$query" ]; then
        printf '%s\n' "specs/$query"
        return 0
    fi

    local -a matches=()
    while IFS= read -r -d '' f; do
        matches+=("${f#$ROOT_DIR/}")
    done < <(find "$ROOT_DIR/specs" -type f -iname "*${query}*" -print0 2>/dev/null)

    if [ "${#matches[@]}" -eq 1 ]; then
        printf '%s\n' "${matches[0]}"
        return 0
    elif [ "${#matches[@]}" -gt 1 ]; then
        echo "Plusieurs specs correspondent à \"$query\" :" >&2
        printf '   - %s\n' "${matches[@]}" >&2
        return 2
    else
        return 1
    fi
}

print_success_banner() {
    echo "${GREEN}${BOLD}"
    echo "  ╔══════════════════════════════════╗"
    echo "  ║                                  ║"
    echo "  ║          TEST RÉUSSI             ║"
    echo "  ║                                  ║"
    echo "  ╚══════════════════════════════════╝"
    echo "${RESET}"
}

print_failure_banner() {
    echo "${RED}${BOLD}"
    echo "  ╔══════════════════════════════════╗"
    echo "  ║                                  ║"
    echo "  ║          TEST ÉCHOUÉ             ║"
    echo "  ║                                  ║"
    echo "  ╚══════════════════════════════════╝"
    echo "${RESET}"
}

# --- Analyse des arguments ---------------------------------------------

POSITIONAL=()
for arg in "$@"; do
    case "$arg" in
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            POSITIONAL+=("$arg")
            ;;
    esac
done

TEST_NAME="${POSITIONAL[0]:-}"
if [ -z "$TEST_NAME" ]; then
    echo "${KO} ${RED}Indique le test à lancer, ex: ./scripts/run-tests.sh login${RESET}" >&2
    echo "" >&2
    echo "Specs disponibles :" >&2
    list_specs >&2
    echo "" >&2
    echo "Lance avec -h ou --help pour voir l'aide complète." >&2
    exit 1
fi
EXTRA_ARGS=("${POSITIONAL[@]:1}")

SPEC_PATH="$(resolve_spec "$TEST_NAME")"
resolve_rc=$?
if [ "$resolve_rc" -eq 1 ]; then
    die "Aucun spec ne correspond à \"$TEST_NAME\" dans specs/."$'\n'"$(list_specs)"
elif [ "$resolve_rc" -eq 2 ]; then
    die "Précise le chemin complet (plusieurs specs correspondent à \"$TEST_NAME\", voir ci-dessus)."
fi

echo "${BOLD}=== Vérification de l'environnement avant de lancer : ${SPEC_PATH} ===${RESET}"

# --- Étape 1 : Node / npm -------------------------------------------------
step_header 1 "Node / npm"
if command -v node >/dev/null 2>&1; then
    echo "   ${OK} node trouvé ($(node -v))"
else
    die "node introuvable. Installe Node.js (voir https://nodejs.org/)."
fi

if command -v npm >/dev/null 2>&1; then
    echo "   ${OK} npm trouvé ($(npm -v))"
else
    die "npm introuvable."
fi

# --- Étape 2 : dépendances npm --------------------------------------------
step_header 2 "Dépendances du projet"
if [ -f "$ROOT_DIR/node_modules/.bin/playwright" ] || [ -f "$ROOT_DIR/node_modules/.bin/playwright.cmd" ]; then
    echo "   ${OK} node_modules présent"
else
    die 'node_modules manquant. Lance "npm install" avant de relancer ce script.'
fi

# --- Étape 3 : CLI Playwright ----------------------------------------------
step_header 3 "CLI Playwright"
pw_version="$(npx playwright --version 2>&1)"
if [ $? -eq 0 ]; then
    echo "   ${OK} ${pw_version}"
else
    die "La CLI Playwright ne répond pas. Vérifie l'installation (\"npm install\")."
fi

# --- Étape 4 : navigateurs installés ---------------------------------------
step_header 4 "Navigateurs Playwright"
if [ -d "$BROWSER_CACHE" ] && find "$BROWSER_CACHE" -maxdepth 1 -iname "chromium-*" -print -quit 2>/dev/null | grep -q .; then
    echo "   ${OK} navigateurs trouvés dans $BROWSER_CACHE"
else
    die 'Aucun navigateur Playwright installé. Lance "npx playwright install" avant de relancer ce script.'
fi

# --- Lancement du test ------------------------------------------------------
echo ""
echo "${BOLD}=== Lancement de ${SPEC_PATH} ===${RESET}"
echo ""
npx playwright test "$SPEC_PATH" --project=chromium "${EXTRA_ARGS[@]}"
exit_code=$?

if [ "$exit_code" -eq 0 ]; then
    print_success_banner
else
    print_failure_banner
fi

exit "$exit_code"
