package = "kong-plugin-session-limiting"
version = "0.0.1-4"
-- TODO: This is the name to set in the Kong configuration `plugins` setting.
-- Here we extract it from the package name.
local pluginName = package:match("^kong%-plugin%-(.+)$")  -- "session-limiting"

supported_platforms = {"linux"}
source = {
  url = "http://github.com/Kong/kong-plugin.git",
  tag = "1.0.0"
}

description = {
  summary = "Kong is a scalable and customizable API Management Layer built on top of Nginx.",
  homepage = "http://getkong.org",
  license = "Apache 2.0"
}

dependencies = {
}

build = {
  type = "builtin",
  modules = {
    -- TODO: add any additional files that the plugin consists of
    ["kong.plugins.session-limiting.migrations.cassandra"] = "kong/plugins/session-limiting/migrations/cassandra.lua",
    ["kong.plugins.session-limiting.migrations.postgres"] = "kong/plugins/session-limiting/migrations/postgres.lua",
    ["kong.plugins.session-limiting.handler"] = "kong/plugins/session-limiting/handler.lua",
    ["kong.plugins.session-limiting.schema"] = "kong/plugins/session-limiting/schema.lua",
    ["kong.plugins.session-limiting.daos"] = "kong/plugins/session-limiting/daos.lua",
    ["kong.plugins.session-limiting.policies"] = "kong/plugins/session-limiting/policies/init.lua",
    ["kong.plugins.session-limiting.policies.cluster"] = "kong/plugins/session-limiting/policies/cluster.lua",
  }
}

