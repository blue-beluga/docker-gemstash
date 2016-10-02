# encoding: UTF-8

GIT_REVISION=$(shell git rev-parse --short HEAD)

REGISTRY = docker.io
FROM = bluebeluga/ruby
REPOSITORY = bluebeluga/gemstash

PUSH_REGISTRIES = $(REGISTRY)
