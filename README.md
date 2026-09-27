# OldRobloxify
Do you like the charm of 2016 Roblox? Well now you can! OldRobloxify is an 2016M client recreation using CoreScripts and more!

PC is highly recommended, Mobile works too except its just a bit buggy lol

# Preview
![Image](https://raw.githubusercontent.com/windowsuser688/OldRobloxify/refs/heads/main/preview.png)

## Loadstring

```lua
option = "2016M"

if option == "2016M" then
	loadstring(game:HttpGet("https://raw.githubusercontent.com/windowsuser688/OldRobloxify/refs/heads/main/Source2016M.lua"))()
elseif option == "2016E" then
	loadstring(game:HttpGet("https://raw.githubusercontent.com/windowsuser688/OldRobloxify/refs/heads/main/Source2016E.lua"))()
elseif option == "2015L" then
	loadstring(game:HttpGet("https://raw.githubusercontent.com/windowsuser688/OldRobloxify/refs/heads/main/Source2015L.lua"))()
elseif option == "2015M" then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/windowsuser688/OldRobloxify/refs/heads/main/Source2015M.lua"))()
else
	print("Unknown client version")
end
```
If loadstring doesn't work, try using the source.
