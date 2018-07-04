---------------------------------------------------------------------------
-- @author Gino
-- @email bombino@fea.st
-- @release v4.0_alpha
---------------------------------------------------------------------------
local icon_theme = require("menubar.icon_theme")
local menubar = require("menubar")
local awful_menu = require("awful.menu")
local pairs = pairs
local ipairs = ipairs
local table = table
local io = io
local coroutine = coroutine

local menugen = { awfulmenutable = {} }

--Recursive Search for subdirectories in local user path (Wine Support)
local handle = io.popen("find ~/.local/share/applications -type d")
for dirname in handle:lines() do
	table.insert(menubar.menu_gen.all_menu_dirs, dirname)
end
handle:close()

--Expecting an wm_name of awesome omits too many applications and tools
menubar.utils.wm_name = ""

-- Use MenuBar Parsing Utils to build StartMenu for Awesome
-- @return awful.menu compliant menu items tree
function menugen.build_menu()
	for k,v in pairs(menubar.menu_gen.all_categories) do
		v["icon_name"] = icon_theme():find_icon_path(v["icon_name"])
		table.insert(menugen.awfulmenutable, { k, {}, v["icon_name"] } )
	end

	table.insert(menugen.awfulmenutable, {"Other", {} } )
	menubar.menu_gen.generate(function(entries) 		
		for i = 1, #entries do
			for j,cat in ipairs(menugen.awfulmenutable) do
				if cat[1] == entries[i]["category"] then
					table.insert( cat[2] , { entries[i].name, entries[i].cmdline, entries[i].icon } )
					break
				end
				--table.insert( cat[2] , { entries[i].name, entries[i].cmdline, entries[i].icon } )
			end
		end
		for i = 1, #menugen.awfulmenutable do
			for j,u in pairs(menubar.menu_gen.all_categories) do
				-- Remove Categories that have no entries
				if #menugen.awfulmenutable[i][2] == {} then
					table.remove(menugen.awfulmenutable[i])
				end 
				-- Change Category Names to Nice Menu Names
				if menugen.awfulmenutable[i][1] == j then
					menugen.awfulmenutable[i][1] = u["name"]
					break
				end
			end
		end
	end)
	
	return menugen.awfulmenutable
end

--@params
--append_menu = list of menu objects to append to start menu
--@returns menu widget singleton with toggle() function to display and destroy object
function menugen.create(append_menu)
	menu_obj = {}
	function menu_obj:toggle()
		if menu_obj.awfulmenu then
			menu_obj.awfulmenu:toggle()
		else
			local menu = {}
			if append_menu then
				menu = append_menu
				menu[#menu+1] = { "Menu", menugen.build_menu() }
			else
				menu = menugen.build_menu()
			end
			menu_obj.awfulmenu = awful_menu( { items = menu, theme = { width = 180 } } )
	
			menu_obj:toggle() 
		end
	end
	return menu_obj
end


return menugen
