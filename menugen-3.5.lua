---------------------------------------------------------------------------
-- @author Gino
-- @release v3.5.6.3
---------------------------------------------------------------------------

local menu_gen = require("menubar.menu_gen")
local menu_utils = require("menubar.utils")
local awful_menu = require("awful.menu")
local pairs = pairs
local ipairs = ipairs
local table = table
local string = string
local next = next
local io = io

module("menugen")

--Built in menubar should be checking local applications directory
menu_gen.all_menu_dirs = { '/usr/share/applications/' }

--Recursive Search for subdirectories in local user path (Wine Support)
local handle = io.popen("find ~/.local/share/applications -type d")
for dirname in handle:lines() do
	table.insert(menu_gen.all_menu_dirs, dirname)
end
handle:close()

--Expecting an wm_name of awesome omits too many applications and tools
menu_utils.wm_name = ""

-- Use MenuBar Parsing Utils to build StartMenu for Awesome
-- @return awful.menu compliant menu items tree
function build_menu()
	local result = {}
	local menulist = menu_gen.generate()

	for k,v in pairs(menu_gen.all_categories) do
		table.insert(result, {k, {}, v["icon"] } )
	end
	
	for k, v in ipairs(menulist) do
		for _, cat in ipairs(result) do
			if cat[1] == v["category"] then
				table.insert( cat[2] , { v["name"], v["cmdline"], v["icon"] } )
				break
			end
		end
	end
	
	-- Cleanup Things a Bit
	for k,v in ipairs(result) do
		-- Remove Unused Categories
		if not next(v[2]) then
			table.remove(result, k)
		else
			--Sort entries Alphabetically (by Name)
			table.sort(v[2], function (a,b) return string.byte(a[1]) < string.byte(b[1]) end)
			-- Replace Catagory Name with nice name
			v[1] = menu_gen.all_categories[v[1]].name
		end
	end

	--Sort Categories Alphabetically Also
	table.sort(result, function(a,b) return string.byte(a[1]) < string.byte(b[1]) end)

	return result
end

--@returns menu widget singleton with toggle() function to display and destroy object
function create(args)
	-- args.append_meny = list of menu objects to append to start menu
	menu_obj = {}
	function menu_obj:toggle()
		if menu_obj.mymainmenu then
			menu_obj.mymainmenu:toggle()
			menu_obj.mymainmenu = nil
		else
			local menu = build_menu()
			if args.append_menu then
				menu[#menu+1] = args.append_menu
			end
			local mymainmenu = awful_menu( { items = menu, theme = { width = 180 } } )
	
			menu_obj.mymainmenu = mymainmenu
			mymainmenu:toggle() 
		end
	end
	return menu_obj
end
