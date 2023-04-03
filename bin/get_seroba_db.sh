# Assume up-to-date if done_seroba exists and the host cannot be resolved (often means the Internet is not available)

if  [ ! -f ${DB_LOCAL}/done_seroba.json ] || \
    [ ! "$(grep 'git' ${DB_LOCAL}/done_seroba.json | sed -r 's/.+: "(.*)",/\1/')" == "${DB_REMOTE}" ] || \
    [ ! "$(grep 'kmer' ${DB_LOCAL}/done_seroba.json | sed -r 's/.+: "(.*)",/\1/')" == "${KMER}" ] || \
    !((git -C ${DB_LOCAL} pull || echo 'Already up-to-date') | grep -q 'Already up[- ]to[- ]date'); then

    rm -rf ${DB_LOCAL}/{,.[!.],..?}*
    git clone ${DB_REMOTE} ${DB_LOCAL}

    CREATE_DB=true

else

    CREATE_DB=false

fi
