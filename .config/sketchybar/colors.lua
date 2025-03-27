return {
	black = 0xff181819,
	white = 0xffe2e2e3,
	red = 0xfffc5d7c,
	green = 0xff9ed072,
	blue = 0xff76cce0,
	yellow = 0xffe7c664,
	orange = 0xfff39660,
	magenta = 0xffb39df3,
	grey = 0xff7f8490,
	transparent = 0x00000000,

	bar = {
		bg = 0x00000000,
		border = 0xff2c2e34,
	},
	popup = {
		bg = 0xc02c2e34,
		border = 0xff7f8490,
	},
	bg1 = 0xff363944,
	bg2 = 0xff414550,

	rainbow = {
		0xff7dc4e4,
		0xff8aadf4,
		0xffb7bdf8,
		0xfff4dbd6,
		0xfff0c6c6,
		0xfff5bde6,
		0xffc6a0f6,
		0xffed8796,
		0xffee99a0,
		0xfff5a97f,
		0xffeed49f,
		0xffa6da95,
		0xff8bd5ca,
		0xff91d7e3,
	},

	with_alpha = function(color, alpha)
		if alpha > 1.0 or alpha < 0.0 then
			return color
		end
		return (color & 0x00ffffff) | (math.floor(alpha * 255.0) << 24)
	end,
}
