#syntax=docker/dockerfile:1.4.2

FROM ubuntu:22.04 AS base

SHELL [ "bash", "-e", "-c"]

COPY <<no-recommends <<no-suggests /etc/apt/apt.conf.d/
APT::Install-Recommends "false";
no-recommends
APT::Install-Suggests "false";
no-suggests

COPY --link --from=ghcr.io/nicholasdille/docker-setup/docker:oras / /