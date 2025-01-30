package.path = package.path .. ";/Users/wilson/.luarocks/share/lua/5.1/?.lua";
package.cpath = package.cpath .. ";/Users/wilson/.luarocks/lib/lua/5.1/?.so";

local jwt = require('resty.jwt');