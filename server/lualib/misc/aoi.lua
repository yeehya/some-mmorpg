local quadtree = require "misc.quadtree"
local print_r = require "print_r"

local aoi = {}

local object = {}
local qtree
local radius

function aoi.init (bbox, r)
	qtree = quadtree.new (bbox.left, bbox.top, bbox.right, bbox.bottom)
	radius = r
end

function aoi.insert (id, pos)
	if object[id] then return end
	
	local tree = qtree:insert (id, pos.x, pos.z)
	if not tree then return end

	local result = {}
	qtree:query (id, pos.x - radius, pos.z - radius, pos.x + radius, pos.z + radius, result)

	local list = {}
	for i = 1, #result do
		local cid = result[i]
		local c = object[cid]
		if c then
			table.insert (list, cid)
			table.insert (c.list, id)
		end
	end

	object[id] = { id = id, pos = pos, qtree = tree, list = list }
	
	return true, list
end

function aoi.remove (id)
	local c = object[id]
	if not c then return end

	if c.qtree then
		c.qtree:remove (id)
	else
		qtree:remove (id)
	end

	object[id] = nil
	return true, c.list
end

function aoi.update (id, pos)
	local ok, olist = aoi.remove (id)
	if not ok then return end

	local nlist
	ok, nlist = aoi.insert (id, pos)
	if not ok then return end

	local ulist = {}
	for _, a in pairs (nlist) do
		local match
		for k, v in pairs (olist) do
			if a == v then
				match = k
				table.insert (ulist, a)
				break
			end
		end
		if match then
			olist[match] = nil
		end
	end

	for _, a in pairs (ulist) do
		for k, v in pairs (nlist) do
			if a == v then
				nlist[k] = nil
				break
			end
		end
	end

	return true, nlist, ulist, olist
end

return aoi