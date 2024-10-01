variable "APTOS_GIT_REVISION" {}

variable "PLATFORM" {}

variable "_PLATFORM_TAG" {
  default = regex_replace(PLATFORM, "/", "-")
}

variable "_REMOTE_CACHE" {
  default = "type=registry,ref=ghcr.io/shinamicorp/aptos:cache-${_PLATFORM_TAG}"
}

function "tag" {
  params = [target]
  result = "ghcr.io/shinamicorp/${target}:${APTOS_GIT_REVISION}-${_PLATFORM_TAG}"
}

target "_common" {
  platforms = [PLATFORM]
  args = {
    APTOS_GIT_REVISION = APTOS_GIT_REVISION
  }
  cache-from = ["type=local,src=./cache/${PLATFORM}", _REMOTE_CACHE]
}

# A cache-only target, just to download/populate the cache.
target "binaries" {
  inherits = ["_common"]
  target   = "binaries"
  output   = ["type=cacheonly"]
  cache-to = ["type=local,dest=./cache/${PLATFORM}", _REMOTE_CACHE]
}

# Single-platform targets.
# Requires creating multi-platform manifest list manually.
target "aptos-node" {
  inherits = ["_common"]
  target   = "aptos-node"
  tags     = [tag("aptos-node")]
}

target "aptos" {
  inherits = ["_common"]
  target   = "aptos"
  tags     = [tag("aptos")]
}

target "default" {
  inherits = ["aptos-node"]
}
