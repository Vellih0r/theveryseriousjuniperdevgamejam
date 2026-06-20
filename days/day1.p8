pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
	pi = 3.1415
	bullets = {}
	
	player_init()
	
	b = nil
	b = load_boss(63,63)
	
	target.x, target.y = get_next_boss_part()
end

function _update()
	if (b) boss_moveset()
	foreach(bullets, bullet_move)
	
 player_movement()
 move_hook()
	
	player_buttons()
end

function _draw()
	cls()
	if (b) b.draw()
	
	-- debug
	-- center
	pset(63,63, 8)
	-- target
	print(target.x .. " " .. target.y)
	
	player_draw()
	
	foreach(bullets, bullet_draw)
end




-->8
--bullets
function bullet_create(x,y,dx,dy)
	add(bullets, {
			x=x,   y=y,
			dx=dx, dy=dy,
			w=4, h=4,
			sprite=17,
		}
	)
end

function bullet_move(b)
	b.x += b.dx
	b.y += b.dy
	if b.x > 128 or b.x < 0 or
		  b.y > 128 or b.y < 0
	then
		del(bullets, b)
	end
end

function bullet_draw(b)
	spr(b.sprite,b.x,b.y)
end
-->8
-- bosses
function boss_hit()
	b.cur_parts -= 1
	if b.cur_parts < 1 then
		b.dead = true
	end
	-- animations
end

function get_next_boss_part()
	local i = b.max_parts - b.cur_parts + 1
	local x = b.x
	local y = b.y-10+i*4
	
	return x,y
end


-- first boss
function load_boss(x,y)
	local boss = {
		x=x, y=y,
		h=16, w=16,
		sprite=14,
		max_parts=4,
		cur_parts=4,
		level=1,
		draw=basic_draw,
		a1 = basic_atack,
	}
	return boss
end

-- atacks!!!

function basic_atack(x,y,n)
	local angle_deg, angle_rad=0
	local bx, by, dx, dy=0
	local radius = 8
	
	for i=0,n do
		angle_deg = i / n * 360
		angle_rad = angle_deg * pi/180
		dx = cos(angle_rad)
		dy = sin(angle_rad)
		bx = x-2 + dx * radius
		by = y-2 + dy * radius
		
		bullet_create(bx,by,dx,dy)
	end
end

function boss_moveset()
	if t() % 2 == 0 then
		b.a1(b.x, b.y,16)
	end
	
	-- demo, delete this
	if t() % 4 == 0 then
		boss_hit()
	end
	
	if b.dead then
		b = bil
	end
end

function basic_draw()
	spr(b.sprite, b.x-b.w/2, b.y-b.h/2, 2,2)
	local start = b.max_parts - b.cur_parts + 1
	for i=start,b.max_parts do
		local x = b.x + 4
		local y = b.y-10+i*4
		line(b.x-4,y,x,y,3)
	end
end
-->8
-- player

function player_init()
	player ={
		x=1,  y=1,
		dx=0, dy=0,
		speed = 4,
		sprite = 1,
		dir = 1,
		ass = false,
		buffer = 0,
	}
	
	hook ={
		x=0,  y=0,
		dx=0, dy=0,
		tx=0, ty=0,
		speed=3,
		is_moving = false,
		visible = false,
		sprite = 44,
		}
	target ={
		x=0, y=0,
	}
end

function player_buttons()
	if player.buffer < 1 and btn(❎) then
		throw_hook()
		player.buffer = 20
	end
	if btn(🅾️)	then 
		delete_hook()
 end
end

function player_draw()
	if player.dir < 0 then
		player.sprite = 1
	else
		player.sprite = 2
	end
	if player.ass then
		player.sprite = 3
	end
	spr(player.sprite, player.x, player.y)
	
	draw_hook(hook)
end

function player_movement()
	local p = player
	
	if p.buffer > 0 then
		p.buffer -= 1
	end

	if btn(⬅️) then
		p.dx -= 1
		p.dir = -1
	end

 if btn(➡️) then
 	p.dx += 1
 	p.dir = 1
 end
 
	if btn(⬆️) then 
		p.dy -= 1
	 p.ass = true
	else 
		p.ass = false  
	end
	
	if (btn(⬇️)) p.dy += 1
	
	-- player.dx =	mid(-1, player.dx, 1)

	player.dx *= 0.2
	player.dy *= 0.2
	
	move_player()
end

-- movement
function move_player()
	local p = player
	
	local next_x = p.x + p.dx 
	
	if p.dx > 0 then 
		if not is_tile_flag(next_x+7,p.y,0)
		and not is_tile_flag(next_x+7,p.y+7,0)
		then
			p.x = next_x
		end

	elseif p.dx < 0 then 
		if not is_tile_flag(next_x,p.y,0)
		and not is_tile_flag(next_x,p.y+7,0)
		then
			p.x = next_x
		end
	end

	local next_y = p.y + p.dy
	
	if p.dy > 0 then 
		if not is_tile_flag(p.x,next_y+7,0)
		and not is_tile_flag(p.x+7,next_y+7,0)
		then
			p.y = next_y
		end
	
	elseif p.dy < 0 then 
		if not is_tile_flag(p.x,next_y,0)
		and not is_tile_flag(p.x+7,next_y,0)
		then
			p.y = next_y
		end 
	end
	-- screen edges
	p.x = mid(0, p.x, 120)
 p.y = mid(0, p.y, 120)
end

-----------------------
-- hook
function throw_hook()
	hook.visible = true

	local angle = atan2(target.x - hook.x,target.y - hook.y)
	
	hook.dx = cos(angle)
	hook.dy = sin(angle)
	
	hook.x = player.x + hook.dx * hook.speed
	hook.y = player.y + hook.dy * hook.speed
	
	hook.tx = target.x
	hook.ty = target.y
	hook.is_moving = true
end

function draw_hook()		
	if hook.visible then  
			spr(hook.sprite,hook.x,hook.y)
			line(player.x+4,player.y+4,
			hook.x+4, hook.y+3,1)
	end
end


function move_hook()
	if hook.visible and hook.is_moving then
	
		hook.x += hook.dx * hook.speed
		hook.y += hook.dy * hook.speed
		
		if abs(hook.x - hook.tx) < 3
		and abs(hook.y - hook.ty) < 3
		then
	 		hook.x = hook.tx
	 		hook.y = hook.ty
	 		hook.is_moving = false
		end
	end
end

function delete_hook()
	hook.visible = false
	hook.x = 0 
	hook.y = 0 
	hook.dx = 0 
	hook.dy = 0
	hook.is_moving = false
end
-->8
-- colision

-- basic box collision
function collide(o1,o2)
	if o1.x < o2.x + o2.w
	or o2.x < o1.x + o1.w
	or o1.y < o2.y + o2.h
	or o2.y < o1.y + o1.h
	then
		return true
	end
	return false
end

function is_tile_flag(x,y,f)
	local map_x = flr(x / 8)
	local map_y = flr(y / 8)
	
	local tile = mget(map_x,map_y)
	return fget(tile, f)
end

-- player colision 
function check_player_colition(f)
	local p = player
	if is_tile_flag(p.x + 1, p.y + 1, f) or
				is_tile_flag(p.x + 6, p.y + 1, f) or 
				is_tile_flag(p.x + 1, p.y + 6, f) or 
				is_tile_flag(p.x + 1, p.y + 1, f) 
	then
			return true -- player touched this flag
	else 
			return false	-- player doesn't touched the flag
	end			
end 
__gfx__
0000000007dddd6006dddd700dddddd006dddd700000000000000000000000000000000000000000000000000000000000000000000000000666666666666660
000000000d55567dd76555d00dddddd0d76555d00000000000000000000000000000000000000000000000000000000000000000000000000666666666666660
0070070006555dddddd555600dddddd0ddd555600000000000000000000000000000000000000000000000000000000000000000000000000666555555556660
0007700007ddd7d00d7ddd700dddddd00d7ddd700000000000000000000000000000000000000000000000000000000000000000000000000666666666666660
0007700000d94d0000d49d0000dddd0000d49d000000000000000000000000000000000000000000000000000000000000000000000000000666666666666660
007007000d7446d00d6447d00d6611d00d6447d00000000000000000000000000000000000000000000000000000000000000000000000000666666555556660
00000000006dd700007dd60000616100007dd6000000000000000000000000000000000000000000000000000000000000000000000000000666555556666660
0000000000d00d0000d00d0000d00d0000d00d000000000000000000000000000000000000000000000000000000000000000000000000000666666666666660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666666666666660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666555555556660
00000000000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666566666666660
00000000009aa9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666666666666660
00000000009aa9000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666666666666660
00000000000990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666555555556660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666665555666660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000666666666666660
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aaaa000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000a000000000000000000000000
000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000aa000000000000000000000000
