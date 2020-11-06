#! /bin/bash
# change credentials
#
# Usage: be [options] who

#    arguments
#      who               name of identity
#
#    options
#
#     Select credentials
#
#     -a|--aws		change/list aws credentials ONLY
#     -g|--gnupg		change/list gnupgcredentials ONLY
#     -p|--pass		change/list pas credentials ONLY
#     -s|--ssh		change/list ssh credentials ONLY
#
#     Select operation
#
#     -l|--list		list availabe credentials.
#     -w|--whoami        list current identities
#
#     Other
#
#     -d|--debug         debug output
#     -h|--help          print usage
#     -v|--verbose       verbose output
#
#  e.g.
#
#   If  ~/.gnupg.$1 exists, link to ~/.gnupg
#   If  ~/.ssh/id_{dsa,rsa}.$1 exists, link to ~/.ssh/id_{dsa,rsa} and add to ssh agent
#   If  ~/.aws/credentials.$1 exists, link to ~/.aws/credentials
#
# TODO
#  - deal with git identities
#     + Use XDG-CONFIG-HOME to switch identities?
#       http://git.661346.n2.nabble.com/What-is-XDG-CONFIG-HOME-for-exactly-td7627117.html
#    + See https://gist.github.com/jexchan/2351996
#  - Deal with .pem files


set -e; set -u

# Helper functions
PROG=`basename "$0" | tr -d '\n'`

function info()  { echo ${PROG}\: info: "$@" 1>&2; }
function warn()  { echo ${PROG}\: warning: "$@" 1>&2; }
function error() { echo ${PROG}\: error: "$@" 1>&2; }
function debug() { [[ -v DEBUG ]] && echo ${PROG}\: debug: "$@" 1>&2 || true ; }
function die()   { echo ${PROG}\: fatal: "$@" 1>&2 && exit 1; }

function usage() {
    debug "in ${FUNCNAME[0]}"

    if [[ "$#" -gt 0 ]]; then
        warn $@
    fi

    cat <<END 1>&2
Usage: be [options] who

   arguments
     who               name of identity

   options

    Select credentials

    -a|--aws		change/list aws credentials ONLY
    -g|--gnupg		change/list gnupgcredentials ONLY
    -p|--pass		change/list pas credentials ONLY
    -s|--ssh		change/list ssh credentials ONLY

    Select operation

    -l|--list		list availabe credentials.
    -w|--whoami        list current identities

    Other

    -d|--debug         debug output
    -h|--help          print usage
    -v|--verbose       verbose output
END
    exit 1
}


function gpg_list() {
    # list available gpg credentail sets (diretories)
    info available GPG credentials sets
    ls -ld ~/.gnupg.*
}

function gpg_whoami() {
    # list current gpg identity
    info Current gpg credential set
    info
    ls -ld ~/.gnupg
    info

}

function gpg_become() {
    # change gpg identity
    rm -f ~/.gnupg || true
    ln -s ~/.gnupg."${who}" ~/.gnupg
}

function aws_list() {
    # list available aws credentials
    cd ~/.aws || die "Error connecting to ~/.aws"

    info available AWS credentials and configs
    ls -ld credentials.* config.*
}

function aws_whoami() {
    # list current aws identity
    cd ~/.aws || die "Error connecting to ~/.aws"

    info Current aws credentials
    info
    ls -ld credentials config
    info
}

function aws_become() {
    # change aws identity
    cd ~/.aws || die "Error connecting to ~/.aws"

    aws_creds="credentials.""${who}"
    if [ ! -f "${aws_creds}"  ]; then
        warn file "${aws_creds}" does not exist.  Not changing aws identity.
    else
        [[ -v VERBOSE ]] && set -x
        rm -f credentials || true
        ln -s "${aws_creds}" credentials
        [[ -v VERBOSE ]] && set +x
    fi

    aws_config="config.""${who}"
    if [ ! -f "${aws_config}"  ]; then
        warn file "${aws_config}" does not exist.  Not installing.
    else
        [[ -v VERBOSE ]] && set -x
        rm -f config || true
        ln -s "${aws_config}" config
        [[ -v VERBOSE ]] && set +x
    fi
}


function ssh_list() {
    # list available ssh credentials
    cd ~/.ssh || die "Error connecting to ~/.ssh"

    info available SSH credentials
    ls -ld id_rsa.* id_dsa.* authorized_keys.*
}

function ssh_whoami() {
    # list current ssh identity
    cd ~/.ssh || die "Error connecting to ~/.ssh"

    info Current SSH identities
    info
    ls -ld id_???  || warn "no ~/.ssh/id_{rsa,dsa} file"
    ls -ld authorized_keys || warn "no authorized_keys file"
    info SSH Agent Identities
    ssh-add -l
    info
}

function ssh_become() {
    # change ssh identity
    cd ~/.ssh || die "Error connecting to ~/.ssh"

    rsa_creds="id_rsa.""${who}"
    dsa_creds="id_dsa.""${who}"
    authorized_keys="authorized_keys.""${who}"

    if [ -f "${dsa_creds}" ]; then
        ssh_creds="${dsa_creds}"
    elif [ -f "${rsa_creds}" ]; then
        ssh_creds="${rsa_creds}"
    else
        echo "No ssh creds found. "${rsa_creds}" and "${dsa_creds}" do not exist."
        exit 1
    fi

    # symlnk ssh creds into ~/.ssh

    target=`basename $ssh_creds ".""${who}"`

    if [ -f "${ssh_creds}"  ]; then
        [[ -v VERBOSE ]] && set +x
        rm -f "${target}" || true
        ln -s "${ssh_creds}" "${target}"
        chmod 400 "${target}"
        ssh-add "${ssh_creds}"
        [[ -v VERBOSE ]] && set -x
    fi


    # symlnk authinfo creds into ~/.ssh

    target=`basename $authorized_keys ".""${who}"`

    if [ -f "${authorized_keys}"  ]; then
        [[ -v VERBOSE ]] && set +x
        rm -f "${target}" || true
        ln -s "${authorized_keys}" "${target}"
        chmod 644 "${target}"
        [[ -v VERBOSE ]] && set -x
    fi

}


function pass_list() {
    # list available pass credentail sets (diretories)
    info available pass credentials sets
    ls -ld ~/.password-store.*
}

function pass_whoami() {
    # list current pass identity
    info Current pass credential set
    info
    ls -ld ~/.password-store
    info
}

function pass_become() {
    # change pass identity
    rm -f ~/.password-store || true
    ln -s ~/.password-store."${who}" ~/.password-store
    gpg_become # need to switch GPG IDs too
}


function org_list() {
    # list available org credentail sets (diretories)
    info available org credentials sets
    ls -ld ~/Org.*
}

function org_whoami() {
    # list current org identity
    info Current org credential set
    info
    ls -ld ~/Org
    info
}

function org_become() {
    # change org identity
    rm -f ~/Org || true
    ln -s ~/Org."${who}" ~/Org
}

#
# "main()" begins here
#

# Defaults
SSH=1
AWS=1
GPG=1
PASSWORD=1
ORG=1



# parse global options

for i in "$@"
do
    case $i in
        -a|--aws)
            AWS=1
            unset SSH
            unset GPG
            unset PASSWORD
            unset ORG
            d_flag="-d"
            shift # past argument with no value
            ;;
        -d|--debug)
            DEBUG=1
            d_flag="-d"
            shift # past argument with no value
            ;;
        -g|--gnupg)
            GPG=1
            unset AWS
            unset SSH
            unset PASSWORD
            unset ORG
            g_flag="-g"
            shift # past argument with no value
            ;;
        -h|--help)
            usage
            ;;
        -l|--list)
            LIST=1
            d_flag="-d"
            shift # past argument with no value
            ;;
        -o|--org)
            unset PASSWORD
            unset AWS
            unset SSH
            unset GPG
            ORG=1
            p_flag="-p"
            shift # past argument with no value
            ;;
        -p|--pass)
            PASSWORD=1
            unset AWS
            unset SSH
            unset GPG
            unset ORG
            p_flag="-p"
            shift # past argument with no value
            ;;
        -s|--ssh)
            SSH=1
            unset AWS
            unset GPG
            unset PASSWORD
            unset ORG
            d_flag="-d"
            shift # past argument with no value
            ;;
        -v|--verbose)
            VERBOSE=1
            v_flag="-v"
            shift # past argument with no value
            ;;

        -w|--whoami)
            WHOAMI=1
            v_flag="-v"
            shift # past argument with no value
            ;;
        -*|--*)
            usage "Unknown state option: $i"
            ;;
    esac
done

# Pull off command line args

if [[ !  -v LIST  && ! -v WHOAMI ]]; then
    if [ "$#" -ne 1 ]; then
        usage need a username
    fi

    who="${1}"
fi

if [[ ! -v SSH && ! -v AWS && ! -v ORG && ! -v PASSWORD && ! -v GPG ]]; then
    die "Must specify at least one of '--aws' '--ssh' '--gnupg' '--pass'"
fi

# Change aws credentials

if [ -v AWS ]; then

    if [[ -v LIST ]]; then
        aws_list
    elif [[ -v WHOAMI ]]; then
        aws_whoami
    else
        aws_become
    fi
fi

# Change ssh credentials

if [ -v SSH ]; then

    if [[ -v LIST ]]; then
        ssh_list
    elif [[ -v WHOAMI ]]; then
        ssh_whoami
    else
        ssh_become
    fi
fi

# Change GPG credentials

if [ -v GPG ]; then

    if [[ -v LIST ]]; then
        echo GPG LIST
        gpg_list
    elif [[ -v WHOAMI ]]; then
        gpg_whoami
    else
        gpg_become
    fi
fi

# Change pass credentials

if [ -v PASSWORD ]; then
    if [[ -v LIST ]]; then
        echo PASSWORD LIST
        pass_list
    elif [[ -v WHOAMI ]]; then
        pass_whoami
    else
        pass_become
    fi
fi

# Change org credentials

if [ -v ORG ]; then
    if [[ -v LIST ]]; then
        echo ORG LIST
        org_list
    elif [[ -v WHOAMI ]]; then
        org_whoami
    else
        org_become
    fi
fi
