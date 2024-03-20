variable "APTOS_GIT_REVISION" {}

variable "PLATFORM" {}

function "tags" {
  params = [target]
  result = ["ghcr.io/shinamicorp/${target}:${APTOS_GIT_REVISION}-${regex_replace(PLATFORM, "/", "-")}"]
}

function "tags_multi_platform" {
  params = [target]
  result = ["ghcr.io/shinamicorp/${target}:${APTOS_GIT_REVISION}"]
}

function "cache" {
  params = [target]
  result = "type=registry,ref=ghcr.io/shinamicorp/${target}:cache-${regex_replace(PLATFORM, "/", "-")}"
}

function "cache_multi_platform" {
  params = [target]
  result = "type=registry,ref=ghcr.io/shinamicorp/${target}:cache"
}

# Single-platform targets.
# Requires creating multi-platform manifest list manually.
target "aptos" {
  platforms = [PLATFORM]
  target = "aptos"
  output = ["type=image"]
  args = {
    APTOS_GIT_REVISION = APTOS_GIT_REVISION
  }
  tags = tags("aptos")
  cache-from = [cache("aptos")] # always merged with children's cache-from
  cache-to = ["${cache("aptos")},mode=max"]
}

target "default" {
  inherits = ["aptos"]
}

# Multi-platform targets.
target "aptos-multi-platform" {
  platforms = ["linux/amd64", "linux/arm64"]
  target = "aptos"
  output = ["type=image"]
  args = {
    APTOS_GIT_REVISION = APTOS_GIT_REVISION
  }
  tags = tags_multi_platform("aptos")
  cache-from = [cache_multi_platform("aptos")] # always merged with children's cache-from
  cache-to = ["${cache_multi_platform("aptos")},mode=max"]
}
