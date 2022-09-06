#!/bin/bash

: "${REGISTRY:=ghcr.io}"
: "${OWNER:=nicholasdille}"
: "${PROJECT:=docker-setup}"
: "${GIT_BRANCH:=main}"

SUM=0
(
    for TOOL in $@; do
        SIZE="$(
            regctl manifest get ${REGISTRY}/${OWNER}/${PROJECT}/${TOOL}:${GIT_BRANCH} --format raw-body \
            | jq -r '.layers[].size' \
            | paste -sd+ \
            | bc
        )"
        SUM=$(( SUM + SIZE ))

        SIZE_HUMAN="$(
            echo "${SIZE}" \
            | numfmt --to=iec --format=%7.1f
        )"
        echo "${SIZE_HUMAN} ${TOOL}"
    done

    SUM_HUMAN="$(
        echo "${SUM}" \
        | numfmt --to=iec --format=%7.1f
    )"
    echo "${SUM_HUMAN}"

) | column --table --table-right=1
