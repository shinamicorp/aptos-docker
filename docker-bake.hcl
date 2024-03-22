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
target "aptos-node" {
  platforms = [PLATFORM]
  target = "aptos-node"
  output = ["type=image"]
  args = {
    APTOS_GIT_REVISION = APTOS_GIT_REVISION
  }
  tags = tags("aptos-node")
  cache-from = [cache("aptos-node")] # always merged with children's cache-from
  cache-to = ["${cache("aptos-node")},mode=max"]
}

target "aptos" {
  inherits = ["aptos-node"]
  target = "aptos"
  tags = tags("aptos")
  # Sharing the same cache with aptos-node
}

target "default" {
  inherits = ["aptos-node"]
}

# Multi-platform targets.
target "aptos-node-multi-platform" {
  platforms = ["linux/amd64", "linux/arm64"]
  target = "aptos-node"
  output = ["type=image"]
  args = {
    APTOS_GIT_REVISION = APTOS_GIT_REVISION
  }
  tags = tags_multi_platform("aptos-node")
  cache-from = [cache_multi_platform("aptos-node")] # always merged with children's cache-from
  cache-to = ["${cache_multi_platform("aptos-node")},mode=max"]
}

target "aptos-multi-platform" {
  inherits = ["aptos-node-multi-platform"]
  target = "aptos"
  tags = tags_multi_platform("aptos")
  # Sharing the same cache with aptos-node
}
