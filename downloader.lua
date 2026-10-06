local _args = ...
if type(_args) ~= "table" then _args = {} end

local isfile = isfile or function(file)
	local suc, res = pcall(function() return readfile(file) end)
	return suc and res ~= nil and res ~= ''
end
local delfile = delfile or function(file) writefile(file, '') end

local function downloadFile(path, func)
	if not isfile(path) then
		local suc, res = pcall(function()
			return game:HttpGet('https://raw.githubusercontent.com/nighterx/RichifyV4/'..readfile('RichifyV4/profiles/commit.txt')..'/'..select(1, path:gsub('RichifyV4/', '')), true)
		end)
		if not suc or res == '404: Not Found' then error(res) end
		if path:find('%.lua') then
			res = '--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.\n'..res
		end
		writefile(path, res)
	end
	return (func or readfile)(path)
end

local function wipeFolder(path)
	if not isfolder(path) then return end
	for _, file in listfiles(path) do
		if file:find('loader') then continue end
		if isfile(file) and select(1, readfile(file):find('--This watermark is used to delete the file if its cached, remove it to make the file persist after vape updates.')) == 1 then
			delfile(file)
		end
	end
end

for _, folder in {'aerov4', 'RichifyV4/games', 'RichifyV4/profiles', 'RichifyV4/assets', 'RichifyV4/libraries', 'RichifyV4/guis'} do
	if not isfolder(folder) then makefolder(folder) end
end

if not isfile('RichifyV4/profiles/commit.txt') then
	writefile('RichifyV4/profiles/commit.txt', 'main')
end

local function downloadPremadeProfiles(commit)
	local httpService = game:GetService('HttpService')
	if isfolder('RichifyV4/profiles/premade') then
		for _, file in listfiles('RichifyV4/profiles/premade') do
			pcall(function() if isfile(file) then delfile(file) end end)
		end
	else
		makefolder('RichifyV4/profiles/premade')
	end
	local success, response = pcall(function()
		return game:HttpGet('https://api.github.com/repos/nighterx/RichifyV4/contents/profiles/premade?ref=' .. commit)
	end)
	if success and response then
		local ok, files = pcall(function() return httpService:JSONDecode(response) end)
		if ok and type(files) == 'table' then
			for _, file in pairs(files) do
				if file.name and file.name:find('.txt') and file.name ~= 'commit.txt' then
					local baseName = (file.name:match('^(.-)%.txt$') or file.name):gsub('%d+$', '')
					local fileId = (game.GameId == 2619619496) and game.GameId or game.PlaceId
					local filePath = 'RichifyV4/profiles/premade/' .. baseName .. tostring(fileId) .. '.txt'
					local ds, dc = pcall(function() return game:HttpGet(file.download_url, true) end)
					if ds and dc and dc ~= '404: Not Found' then writefile(filePath, dc) end
				end
			end
		end
	end
end

if not shared.VapeDeveloper then
	local commit = isfile('RichifyV4/profiles/commit.txt') and readfile('RichifyV4/profiles/commit.txt') or ''
	local latest = isfile('RichifyV4/profiles/latest.txt') and readfile('RichifyV4/profiles/latest.txt') or ''
	if #commit ~= 40 then
		local ok, res = pcall(function()
			return game:HttpGet('https://api.github.com/repos/nighterx/RichifyV4/commits/main', true)
		end)
		if ok and res then
			local h = res:match('"sha":"([a-f0-9]+)"')
			if h and #h == 40 then commit = h end
		end
		if #commit ~= 40 then commit = 'main' end
		latest = commit
		pcall(writefile, 'RichifyV4/profiles/latest.txt', latest)
	elseif #latest == 40 and latest ~= commit then
		commit = latest
	end
	task.spawn(function()
		local ok, res = pcall(function()
			return game:HttpGet('https://api.github.com/repos/nighterx/RichifyV4/commits/main', true)
		end)
		if ok and res then
			local h = res:match('"sha":"([a-f0-9]+)"')
			if h and #h == 40 then
				pcall(writefile, 'RichifyV4/profiles/latest.txt', h)
			end
		end
	end)
	if commit ~= 'main' and (isfile('RichifyV4/profiles/commit.txt') and readfile('RichifyV4/profiles/commit.txt') or '') ~= commit then
		wipeFolder('aerov4')
		wipeFolder('RichifyV4/games')
		wipeFolder('RichifyV4/guis')
		pcall(function() if isfile('RichifyV4/guis/new.lua') then delfile('RichifyV4/guis/new.lua') end end)
		wipeFolder('RichifyV4/libraries')
		if isfolder('RichifyV4/profiles/premade') then
			for _, file in listfiles('RichifyV4/profiles/premade') do
				pcall(function() if isfile(file) then delfile(file) end end)
			end
		end
	end
	local oldCommit = isfile('RichifyV4/profiles/commit.txt') and readfile('RichifyV4/profiles/commit.txt') or ''
	writefile('RichifyV4/profiles/commit.txt', commit)
	local needPremade = (oldCommit ~= commit)
	if not needPremade then
		needPremade = true
		if isfolder('RichifyV4/profiles/premade') then
			for _ in listfiles('RichifyV4/profiles/premade') do
				needPremade = false
				break
			end
		end
	end
	if needPremade then
		pcall(downloadPremadeProfiles, commit)
	end
end

return loadstring(downloadFile('RichifyV4/main.lua'), 'main')({
	Closet = _args.Closet,
})
