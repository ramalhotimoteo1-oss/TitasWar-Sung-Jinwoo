#!/bin/sh

# Arquivo de cache de traducoes
TRANSLATIONS_FILE="$HOME/twm/translations.po"
SOURCE="en"

# Funcao para traduzir via API (curl + jq)
get_translation() {
    target="$1"
    text="$2"
    url="https://translate.disroot.org/translate"
    data="{\"q\":\"${text}\",\"source\":\"${SOURCE}\",\"target\":\"${target}\",\"format\":\"text\",\"alternatives\":0,\"api_key\":\"\"}"
    curl -s -X POST "$url" -H "Content-Type: application/json" -d "$data" | jq -r '.translatedText // empty'
}

# Funcao para carregar traducoes do arquivo de cache
# (sh nao tem arrays associativos — o cache e consultado via grep no arquivo)
load_translations() {
    if [ ! -f "$TRANSLATIONS_FILE" ]; then
        touch "$TRANSLATIONS_FILE" 2>/dev/null
    fi
}

# Funcao central: traduz e armazena em cache
# Uso: translate_and_cache "$LANGUAGE" "texto"
translate_and_cache() {
    target_lang="$1"
    text="$2"

    # Remove espacos extras
    text=`echo "$text" | xargs 2>/dev/null || echo "$text"`

    # Detecta marcador de funcao (__FUNC__)
    is_func=""
    case "$text" in
        __FUNC__*)
            is_func="yes"
            text=`echo "$text" | sed 's/^__FUNC__ //'`
            ;;
    esac

    # Idioma ingles: retorna sem traduzir
    if [ "$target_lang" = "en" ] || [ -z "$target_lang" ]; then
        echo "$text"
        return 0
    fi

    # Detecta prefixo do tipo "A- ", "1- ", etc. quando marcador __FUNC__ presente
    prefix=""
    rest="$text"
    if [ "$is_func" = "yes" ]; then
        prefix=`echo "$text" | sed -n 's/^\([^[:space:]]*-\) .*/\1 /p'`
        if [ -n "$prefix" ]; then
            rest=`echo "$text" | sed "s/^${prefix}//"`
        fi
    fi

    # Tenta buscar no cache
    translated_text=`grep "^${text}|" "$TRANSLATIONS_FILE" 2>/dev/null | tail -n 1 | cut -d'|' -f2-`

    if [ -n "$translated_text" ]; then
        echo "$translated_text"
        return 0
    fi

    # Realiza traducao via API
    if [ -n "$prefix" ]; then
        raw=`get_translation "$target_lang" "$rest"`
        translated_text="${prefix}${raw}"
    else
        translated_text=`get_translation "$target_lang" "$text"`
    fi

    # Se falhar, retorna texto original
    if [ -z "$translated_text" ]; then
        echo "$text"
        return 0
    fi

    # Salva no cache
    echo "${text}|${translated_text}" >> "$TRANSLATIONS_FILE"

    echo "$translated_text"
}

# Inicializa cache
load_translations
