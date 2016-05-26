if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    brew update
    brew install ocaml opam
    brew install gcc --enable-fortran
fi

make odepack  # Download the ODEPACK FORTRAN code

OPAM_PKGS="oasis base-bytes"

export OPAMYES=1

if [ -f "$HOME/.opam/config" ]; then
    opam update
    opam upgrade
else
    opam init
fi

if [ -n "${OPAM_SWITCH}" ]; then
    opam switch ${OPAM_SWITCH}
fi
eval `opam config env`

opam install $OPAM_PKGS

export OCAMLRUNPARAM=b
make
make test
