# Return boolean of CREATE_DB, download if necessary

# Check if GET_SEROBA_DB and CREATE_SEROBA_DB has run successfully on the database at the specific link, CREATE_SEROBA_DB used the specific Kmerm and pull to check if SeroBA database is up-to-date.
# If outdated or does not exist: remove files in database directory and clone, set CREATE_DB to true

# Assume up-to-date if done_seroba.json passes checks and the host cannot be resolved to allow offline usage

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
