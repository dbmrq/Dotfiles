-- Hide status bar
function Status:redraw()
	return {}
end

-- Add file info to header (right side)
Header:children_add(function(self)
	local h = self._current.hovered
	if not h then
		return ""
	end

	-- Get file permissions
	local perm = h.cha:perm() or ""

	-- Get file size (only for files, not directories)
	local size = ""
	if not h.cha.is_dir then
		local len = h.cha.len or 0
		if len < 1024 then
			size = string.format("%dB", len)
		elseif len < 1024 * 1024 then
			size = string.format("%.1fK", len / 1024)
		elseif len < 1024 * 1024 * 1024 then
			size = string.format("%.1fM", len / (1024 * 1024))
		else
			size = string.format("%.1fG", len / (1024 * 1024 * 1024))
		end
	end

	-- Get position in file list
	local folder = self._current
	local pos = string.format("%d/%d", folder.cursor + 1, #folder.files)

	-- Build the info string
	local parts = {}
	if perm ~= "" then
		table.insert(parts, perm)
	end
	if size ~= "" then
		table.insert(parts, size)
	end
	table.insert(parts, pos)

	return ui.Line(" " .. table.concat(parts, " "))
end, 500, Header.RIGHT)
