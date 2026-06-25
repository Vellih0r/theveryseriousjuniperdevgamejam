pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
function _init()
	pi = 3.1415
	
	player_init()
	minigame = false
	minigame_buffer = 0
	gamestate = "game"
	
	boss = nil
	boss = load_boss(63,63)

	coil_num = 132
	gear_angle = 0
	gear_speed = 2
end

function _update()

	-- get target for hook
	if boss then
		target.x, target.y = get_next_boss_part()
	else
		target.x = player.x + player.dx*20
		target.y = player.y + player.dy*20
	end
	
	-- boss
	if (boss) boss_moveset()
	-- bullets
	foreach(bullets, bullet_move)
	foreach(spirals, spiral_move)
	

	-- move player or minigame
	if minigame then
		minigame_gameplay()
	elseif minigame_buffer < 1 then
		-- player
		player_movement()
		player_locations()
		move_hook()
		player_buttons()
	else
		-- buffer to wait after minigame
		minigame_buffer  -= 1
 end
 
 if gamestate == "gameover" then 
		if btnp(❎) then 
			player_init()
			player.buffer = 10
			gamestate = "game" 
		end
	end
	
end

function _draw()
	cls()
--	pal(13,10)
--	pal(5,3)
	if gamestate == "game" then
		map()
		-- boss
		if (boss) boss.draw()
		
		-- player
		player_draw()
		
		-- bullets
		foreach(bullets, bullet_draw)
		foreach(aim_lasers, draw_aim_laser)
		foreach(spirals, bullet_draw)
		-- ui
		draw_ui()
		
		-- rotate gear
--		if player.locx == 0 then
--			local sa = gear_angle/360
--				rspr(12*8,0,32,32,sa,64,64,46,46)
--			gear_angle -= gear_speed
--		end
		-- minigame ui
		draw_minigame_ui()
		
		elseif gamestate == "gameover" then
				print("you died bitch", 38, 54, 8)
    print("the city will never be awaken", 8, 64, 9)
    print("press ❎ to restart", 28, 74, 7)
		end
end




-->8
--bullets
function bullet_create(x,y,dx,dy,sprite,ttl,w,h)
	local sp = sprite or 17
	local width  = w or 4
	local height = h or 4
	add(bullets, {
			x=x,   y=y,
			dx=dx, dy=dy,
			w=width, h=height,
			sprite=sp,
			ttl=ttl,
			start=ttl,
		}
	)
end

function spiral_create(x,y,dx,dy,i,n,lt)
	local sp = 17
	local width  = 4
	local height = 4
	add(spirals, {
			x=x,   y=y,
			dx=dx, dy=dy,
			w=width, h=height,
			sprite=sp,
			lifetime=lt,
			a=i/n,
			dead=false,
		}
	)
end

function spiral_move(s)
	s.x += s.dx * 2
	s.y += s.dy * 2
	
	-- collide player
	-- shift hitbox to centerplayer.x += 2
	player.x += 2
	player.y += 2
	local hit = collide(player, s)
	player.x -= 2
	player.y -= 2
	if hit and not player.hit then
		player_hurt()
	end
	player.hit = hit
	
	s.a += 0.01
	s.dx = cos(s.a) 
	s.dy = sin(s.a)
	
	-- screen edges
	if s.lifetime < 1 then
		s.dead = true
	else
		s.lifetime -= 1
	end
	
	if s.dead then
		del(spirals, s)
	end
end

function bullet_move(b)
	b.x += b.dx
	b.y += b.dy
	
	-- moving lasers
	if b.vivi then
		if b.vivi == "vertical"
		then
			-- bounce out of screet
			if b.x + b.dx >= 126 then
			
				b.dx *= -1
			end
		elseif b.vivi == "horizontal"
		then
			if b.y + b.dy >= 126 then
				b.dy *= -1
			end
		end
	end
	
	-- if not alarm laser
	if not b.ttl or b.ttl < b.start-30 then
			-- collide player
			-- shift hitbox to centerplayer.x += 2
			player.x += 2
			player.y += 2
		local hit = collide(player, b)
			player.x -= 2
			player.y -= 2
		if hit and not player.hit then
			player_hurt()
		end
		player.hit = hit
	end
	
	-- screen edges
	if b.x > 128 or b.x < 0 or
		  b.y > 128 or b.y < 0
	then
		b.dead = true
	end
	
	-- laser lifetime
	if b.ttl then
		if b.ttl < 1 then
			b.dead = true
		else
			b.ttl -= 1
		end
	end
	
	if (b.dead) del(bullets, b)
end

function bullet_draw(b)
	-- bullet
	if (not b.ttl) spr(b.sprite,b.x,b.y)
	
	draw_square_laser(b)
	draw_vivi_lasers(b)
	
end

function draw_aim_laser(t)
	local b = boss
	local angle_deg = t.i / t.n * 360
	local angle_rad = angle_deg * pi/180
	
	local dx = cos(angle_rad+t.s) 
	local dy = sin(angle_rad+t.s)
	t.x = b.x - 2 + dx * t.r
	t.y = b.y - 2 + dy * t.r
	t.i += 1
	
	line(b.x,b.y, t.x,t.y, 8)
	if t.i > t.n/12 then
		del(aim_lasers, t)
	end
	
	if laser_hit(b.x,b.y,t.x,t.y) then
		player_hurt()
	end
end

function laser_hit(x1, y1, x2, y2)
 local px = player.x + 2
 local py = player.y + 2

 for i=0,1,0.05 do
  local x = x1 + (x2 - x1) * i
  local y = y1 + (y2 - y1) * i

  if abs(px - x) < 2 and abs(py - y) < 2 then
   return true
  end
 end

 return false
end

function draw_square_laser(l)
	if (l.vivi) return
	
	if l.ttl then
	-- alarm
		if l.ttl > l.start-30 then
			pal(7,8)
		elseif l.ttl % 2 == 0 then
			pal(7,14)
		else
			pal()
		end
		spr(l.sprite, l.x, l.y, 2,2)
	end
end

function draw_vivi_lasers(l)
	if (not l.vivi) return
	
	if l.ttl > l.start-30 then
		pal(7,8)
	elseif l.ttl % 2 == 0 then
		pal(7,14)
	else
		pal()
	end 
	
	if l.vivi == "vertical"
	then
		spr(l.sprite, l.x, l.y, 1,2)
	elseif l.vivi == "horizontal"
	then
		spr(l.sprite, l.x, l.y, 2,1)
	end
end
-->8
-- bosses
function boss_hit()
	boss.cur_parts -= 1
end

function get_next_boss_part()
	local b = boss
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
		sprite=174,
		max_parts=4,
		cur_parts=1,
		level=1,
		cooldown = 30,
		draw=basic_draw,
		spam=0,
		halfrot=false,
	}
	return boss
end

-- ai of boss
function boss_moveset()
	if (boss.dead) boss = nil
	
	local b = boss
	if (b == nil) return
	
	-- death condition
	if b.cur_parts < 1 then
		b.dead = true
		-- animation
	end
	
	-- cooldown math
	if b.cooldown > 0 then
		b.cooldown -= 1
	end
	
	if b.cooldown < 1 and b.spam > 0 then
		spiral_shot(b.x-4,b.y-4)
		if b.spam == 1 then
			b.cooldown = 30*3
			if (b.half_rot) b.half_rot=false
		else
			b.cooldown = 1
		end
		b.spam -= 1
		if b.half_rot then
			rotation += 0.5
		else
			rotation += 0.2
		end
	end
	
	
	if b.cooldown < 1 then
		
		-- choose attack
		local r = rnd()
		
		if r < 0.1 then
			rotation = 0
			b.spam = 90
		elseif r < 0.2 then
			spiral_attack(b.x,b.y,10)
			b.cooldown = 30*3
		elseif r < 0.3 then
			circle_attack(b.x, b.y,16)
			rotation += 0.1
			b.cooldown = 30*1
		elseif r < 0.4 then
			arc_attack(b.x,b.y,4)
			b.cooldown = 30*2
		elseif r < 0.5 then
			arc_attack(b.x,b.y,8)
			b.cooldown = 30*3
		--laser
		elseif r < 0.6 then
			laser_square_attack(90)
			b.cooldown = 30*6
		elseif r < 0.7 then
			if rnd() < 0.5 then
				laser_go_vivi()
			else
				laser_go_vivi(1)
			end
			b.cooldown = 30*6
		elseif r < 0.8 then
			laser_go_vivi()
			laser_go_vivi(1)
			b.cooldown = 30*6
		elseif r < 0.9 then
			b.half_rot = true
			rotation = 0
			b.spam = 90
		else
			aim_laser()
			b.cooldown = 30*2
		end
	end
	
	if b.dead then
		b = nil
	end
end

function basic_draw()
	local b = boss
	spr(b.sprite, b.x-b.w/2, b.y-b.h/2, 2,2)
	local start = b.max_parts - b.cur_parts + 1
	for i=start,b.max_parts do
		local x = b.x + 4
		local y = b.y-10+i*4
		line(b.x-4,y,x,y,3)
	end
end

-- atacks!!!

function spiral_shot(x, y)
	local dx = cos(rotation)
	local dy = sin(rotation)

	bullet_create(x, y, dx, dy)

	rotation += 0.02
end

function spiral_spam(x,y,n)
	local angle_deg = 0
	local angle_rad = 0
	local bx, by = 0
	local dx, dy=0
	local radius = 8
	
	local angle = 360
	
	for i=1,n do
		angle_deg = i / n * angle + rotation
		angle_rad = angle_deg * pi/180
		dx = cos(angle_rad) 
		dy = sin(angle_rad)
		-- position
		bx = x-2 + dx * radius
		by = y-2 + dy * radius
		
		bullet_create(bx,by,dx,dy)
	end
end

function spiral_attack(x,y,n)
	local angle_deg = 0
	local angle_rad = 0
	local bx, by = 0
	local dx, dy=0
	local radius = 8
	
	local angle = 360
	
	for i=1,n do
		angle_deg = i / n * 360 + rotation
		angle_rad = angle_deg * pi/180
		dx = cos(angle_rad) 
		dy = sin(angle_rad)
		-- position
		bx = x-2 + dx * radius
		by = y-2 + dy * radius
		
		spiral_create(bx,by,dx,dy,i,n,90)
	end
end

function circle_attack(x,y,n)
	local angle_deg = 0
	local angle_rad = 0
	local bx, by = 0
	local dx, dy=0
	local radius = 8
	
	local angle = 360
	
	for i=1,n do
		angle_deg = i / n * angle
		angle_rad = angle_deg * pi/180
		dx = cos(angle_rad) 
		dy = sin(angle_rad)
		-- position
		bx = x-2 + dx * radius
		by = y-2 + dy * radius
		
		bullet_create(bx,by,dx,dy)
	end
end

function arc_attack(x,y,n)
	local bx, by = 0
	local dx, dy=0
	local radius = 8
	
	local spread = 10 * pi/180
	local base_angle = atan2(player.x-boss.x,
				          player.y-boss.y)
	
	for i=1,n do
		local offset
		
		if n == 1 then
			offset = 0
		else
			offset = -spread/2 + (i-1)*spread/(n-1)
		end
		
		local angle = base_angle + offset
		
		dx = cos(angle) 
		dy = sin(angle)
		-- position
		bx = x-2 + dx * radius
		by = y-2 + dy * radius
		
		bullet_create(bx,by,dx,dy)
	end
end

function laser_square_attack(ttl)
	-- sprite
	local laser = 18
	for x=1,120,16 do
		for y=1,120,16 do
			bullet_create(x,y,0,0,19,ttl,8,1)
			bullet_create(x,y,0,0,18,ttl,1,8)
		end
	end
end

function laser_go_vivi(vertical)
	
	local ttl = 300
	
	local idx = #bullets
	for i=0,120,16 do
		idx += 1
		
		if not vertical then
			bullet_create(0,i,1,0,5,ttl,1,8)
			
			local laser = bullets[idx]
			laser.vivi = "vertical"
		else
			bullet_create(i,0,0,1,6,ttl,8,1)
			
			local laser = bullets[idx]
			laser.vivi = "horizontal"
		end	
	end
end

function aim_laser()
	local p = player
	local b = boss
	local t = {x=0,
		y=0,
		i=0,
		n=360,
		r=90,
		s=0
	}
	
	local px = player.x - player.locx
	local py = player.y - player.locy
	local start = 0
	if px <= 64 then
		if py <= 64 then
			start = pi
		else
			start = pi*2
		end
	else
		if py >= 64 then
			start = pi*3
		else
			start = pi/4
		end
	end
	t.s = start

	add(aim_lasers, t)
end
-->8
-- player

function player_init()
	player ={
		x=1,  y=1,
		dx=0, dy=0,
		last_dx = 0,
		last_dy = 0,
		w=4, h=4,
		speed = 1,
		max_speed = 1,
		max_hp = 3,
		cur_hp = 3,
		hit = false,
		locx=0, locy=0,
		
		
		sprite = 1,
		dir = 1,
		ass = false,
		blink = 0,
		
		buffer = 0,
		dash_cd = 0,
		xrelease = true,
		iframes = 0,
		max_iframes = flr(30 * 0.8),
	}
	
	hook ={
		x=0,  y=0,
		dx=0, dy=0,
		tx=0, ty=0,
		speed=3,
		is_moving = false,
		visible = false,
		sprite = 207,
		}
	target ={
		x=0, y=0,
	}
	bullets = {}
	spirals = {}
	aim_lasers = {}
	rotation = 0
end

function player_buttons()
	local h = hook
	local p = player
	if btn(❎) and p.buffer < 1 then
		-- thorw
		if not h.visible and p.xrelease then
			hook_throw()
			p.buffer = 20
			
		-- minigame condition
		elseif not h.is_moving 
			  and not minigame then
			 -- if boss is dead
			 -- there r no sence
			 if not boss then
				 delete_hook()
				 p.buffer = 10
				 return
			 end
				start_mini_game()
				minigame = true
		end
		p.xrelease = false
	end
	
	if not btn(❎) then
		p.xrelease = true
	end
	
	if btn(🅾️)	then 
		dash()
 end
end

function player_draw()
	local p = player
	
	-- choose sprite
	if p.dir < 0 then
		p.sprite = 1
	else
		p.sprite = 2
	end
	
	if p.ass then
		p.sprite = 3
	end
	
	
	-- blinking on iframes
	if p.blink != 0 then
		p.blink -= 1
	end
	if p.blink == 0 or
		p.blink % 6 == 0 then
		spr(p.sprite,p.x,p.y)
	end
	
	draw_hook(hook)
end

function player_hurt()
	local p = player
	
	if p.iframes < 1 then
		p.cur_hp -= 1
		delete_hook()
		p.iframes = p.max_iframes
		p.blink = p.max_iframes
		-- animation
		-- sfx
		
		-- death
		if p.cur_hp < 1 then
--			cls()
--			pal(13,8)
--			spr(p.sprite,p.x,p.y)
--			stop()
			gamestate ="gameover"
		end
	end
end

function dash()
	local p = player
	
	if p.dash_cd < 1 then
		pal(13,7)
		p.x += p.last_dx*7
		p.y += p.last_dy*7
		p.dash_cd = 30
		p.iframes = 6
	end
end

function player_locations()
	camera(player.locx,player.locy)
	player_enter_door()
	player_exit_door()
	
	player_transit()
end

function player_enter_door()
	if player.locx == 128
	and player.locy == 128
	and check_player_colision(7)
		then
		
		local px = player.x - player.locx
		local py = player.y - player.locy
		local side = which_side()
		
		player.locx = 128*3
		player.locy = 0
		
		-- bottom
		if side == 1 then
			player.x = player.locx+px
			player.y = player.locy+128-16
		end
		-- top
		if side == 2 then
			player.x = player.locx+px
			player.y = player.locy + 8
		end
		-- left
		if side == 3 then
			player.x = player.locx + 8
			player.y = player.locy+py
		end
		-- right
		if side == 4 then
			player.x = player.locx+128-16
			player.y = player.locy+py
		end
	end
end

function player_exit_door()
	if player.locx == 128*3
		and player.locy == 0 then
		local px = player.x - player.locx
		local py = player.y - player.locy
		-- return to left door
		if px < 4
			and py > 56
			and py < 72
		then
			player.x = 128*2-90
			player.y = 128+py
			-- move camera
			player.locx = 128
			player.locy = 128
		end
		
		-- right
		if px > 128 - 10
			and py > 56
			and py < 72
		then
			player.locx = 128
			player.locy = 128
			player.x = 128*2-40
			player.y = 128+py
		end
		
		-- top
		if py < 0 + 4
			and px > 56
			and px < 72
		then
			player.locx = 128
			player.locy = 128
			player.x = 128+px
			player.y = 128+30
		end
		
		-- bottom
		if py > 128 - 10
			and px > 56
			and px < 72
		then
			player.locx = 128
			player.locy = 128
			player.x = 128+px
			player.y = 128*2-34
		end
	end
end

function which_side()
	local y = 64
	local x = 64
	local px = player.x - player.locx
	local py = player.y - player.locy
	
	-- from bottom
	if (py>=y+10 and py<=y+18) return 1
	-- from top
	if (py>=y-28 and py<=y-18) return 2
	-- left
	if (px>=x-28 and px<=x-10) return 3
	-- right
	if (px>=x+10 and px<=x+18) return 4
end

function player_transit()
	local p = player
	-- skip inside room
	if (p.locx == 128*3 and p.locy == 0) return
	
	-- normolize coords
	local x = p.x - p.locx
	local y = p.y - p.locy
	
	if y > 54 and y < 72 and
		x > 128-10
		then
		p.x += 16
		p.locx += 128
	end
	
	if y > 54 and y < 72 and
		x < 2
		then
		p.x -= 20
		p.locx -= 128
	end
	
	if x > 54 and x < 72 and
		y < 2
		then
		p.y -= 20
		p.locy -= 128
	end
	
	if x > 54 and x < 72 and
		y > 128-10
		then
		p.y += 16
		p.locy += 128
	end
	
end

function player_movement()
	local p = player
	
	-- cooldowns
	if p.buffer > 0 then
		p.buffer -= 1
	end
	if p.dash_cd > 0 then
		p.dash_cd -= 1
	end
	-- iframes
	if p.iframes > 0 then
		p.iframes -= 1
	else
		pal()
	end

	if btn(⬅️) then
		p.dx -= p.speed
		p.dir = -1
	end

 if btn(➡️) then
 	p.dx += p.speed
 	p.dir = 1
 end
 
	if btn(⬆️) then 
		p.dy -= p.speed
		p.ass = true
	else 
		p.ass = false  
	end
	
	if (btn(⬇️)) p.dy += p.speed
	
	-- max speed
	p.dx =	mid(-p.max_speed, p.dx, p.max_speed)
	p.dy =	mid(-p.max_speed, p.dy, p.max_speed)

	if not btn(➡️) and not btn(⬅️) then
		p.dx *= 0.8
	else
		p.dx = flr(p.dx+0.5)
	end
	if not btn(⬆️) and not btn(⬇️) then
		p.dy *= 0.8
	else
		p.dy = flr(p.dy+0.5)
	end
	
	-- save as last used
	if p.dx > 0.5 or
		  p.dx < 0.5 then
		p.last_dx = p.dx
	end
	if p.dy > 0.5 or
		  p.dy < 0.5 then
		p.last_dy = p.dy
	end
	
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
	p.x = mid(p.locx, p.x, p.locx+120)
 p.y = mid(p.locy, p.y, p.locy+120)
end

-----------------------
-- hook
function go_to_obj(o,o2,dx_in,dy_in,speed_in)
	-- arguments:
	-- object1. object2, obj1.dx, obj2.dy
	local speed = speed_in or o.speed
	local dx1 = dx_in or o.dx
	local dy1 = dy_in or o.dy
	
	local nextx = o.x + dx1 * speed
	local nexty = o.y + dy1 * speed

	local angle = atan2(o2.x-nextx, o2.y-nexty)
	
	local dirx = cos(angle)
	local diry = sin(angle)
	return {
		dx=dirx,
		dy=diry,
		nx=nextx,
		ny=nexty,
	}
end

function hook_throw()
	hook.visible = true
	
	local dir = go_to_obj(player,target,hook.dx,hook.dy,hook.speed)
	hook.x = dir.nx
	hook.y = dir.ny
	hook.dx = dir.dx
	hook.dy = dir.dy
	
	
	hook.tx = target.x
	hook.ty = target.y
	hook.is_moving = true
end

function draw_hook()		
	if hook.visible then
			if hook.x < player.x then
				spr(hook.sprite,hook.x-4,
				 hook.y-4, 1,1,0)
			else
				spr(hook.sprite,hook.x-4,
				 hook.y-4)
			end
			line(player.x+4,player.y+4,
			hook.x-1, hook.y-1,1)
	end
end


function hook_boost()
	local p = player
	local h = hook
	
	local dir = go_to_obj(p, h)
	p.dx += dir.dx * 2
	p.dy += dir.dy * 2
end

function move_hook()
	if hook.visible and hook.is_moving then
	
		hook.x += hook.dx * hook.speed
		hook.y += hook.dy * hook.speed
		
		if abs(hook.x - hook.tx) < 4
		and abs(hook.y - hook.ty) < 4
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
	and o2.x < o1.x + o1.w
	and o1.y < o2.y + o2.h
	and o2.y < o1.y + o1.h
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
function check_player_colision(f)
	local p = player
	if is_tile_flag(p.x + 1, p.y + 1, f) or
				is_tile_flag(p.x + 6, p.y + 1, f) or 
				is_tile_flag(p.x + 1, p.y + 6, f) or 
				is_tile_flag(p.x + 6, p.y + 6, f) 
	then
			return true -- player touched this flag
	else 
			return false	-- player doesn't touched the flag
	end			
end 
-->8
-- ui

function draw_ui()
	display_hp()
 draw_coil()

end

function draw_minigame_ui()
	if hook.visible and not hook.is_moving
	and minigame
	then  
		draw_arrows()
	end
end
-- hp
function display_hp()
	local curhp = player.cur_hp
	local maxhp = player.max_hp
	local x = 70
	local y = 1
	-- current hp
	for i=1,curhp do
		x += 8
		spr(42,x,y)
	end
	-- empty hp
	for i=1,maxhp-curhp do
		x += 8
		spr(26,x,y)
	end
end

-- mini game 
function start_mini_game()
	current_arrow = 1
	arrows = {}
	for i = 1,4,1 do
		local arrow_sprite = 22+flr(rnd(4))
		add(arrows, {id = arrow_sprite, filled=false})
	end
end
 
function stop_minigame()
	minigame = false
	minigame_buffer = 5
end
	 
function draw_arrows()

 local next_sprite_x_pos = 40 
	
	for arr in all(arrows) do
		next_sprite_x_pos += 8
			if arr.filled then 
				spr(arr.id+ 16,next_sprite_x_pos,104)
			else
				spr(arr.id,next_sprite_x_pos,104)
			end
	end
end

function minigame_gameplay()
	if (not minigame) return
	
	local target_arrow = arrows[current_arrow]
	-- player_input is the default arrow sprite id + 16 (filled)
	
	local player_input = 0
	if (btnp(⬆️)) then player_input = 22 end
	if (btnp(⬇️)) then player_input = 23 end
	if (btnp(⬅️)) then player_input = 24 end
	if (btnp(➡️)) then player_input = 25 end

	if player_input > 0 then 
			if player_input == target_arrow.id then
						target_arrow.filled = true
						current_arrow += 1
						coil_num += 2
						
						-- wincondition!!!
						if current_arrow > 4 then
								coil_num = 132
								stop_minigame()					
								delete_hook()
								-- damage boss!!!
								if (boss) boss_hit()
						end
			else
				coil_num = 132 
				stop_minigame()
			end
	end
end

function draw_coil()
	spr(coil_num,105,1,2,2)
end


function rspr(sx,sy,sw,sh,a,dx,dy,dw,dh)
	local sx,sy,sw,sh,a,dx,dy,dw,dh=
		sx or 0, sy or 0,
		sw or 8, sh or 8,
		a or 0,
		dx or 0, dy or 0,
		dw or 8, dh or 8
	
	local s1,c1 = sin(a+0+0.125),cos(a+0+0.125)
	local half_dw,half_dh = dw/2,dh/2
	local x1,y1 = half_dw*c1,half_dh*s1
	local x2,y2 = half_dw*s1,half_dh*-c1
	local x3,y3 = half_dw*-c1,half_dh*-s1
	local x4,y4 = half_dw*-s1,half_dh*c1
	
	for y=0,dh-1 do
		local ty = y/dh
		local stx,sty = x2+(x3-x2)*ty,y2+(y3-y2)*ty
		local enx,eny = x1+(x4-x1)*ty,y1+(y4-y1)*ty
		for x=0,dw-1 do
			local tx = x/dw
			local px,py = stx+(enx-stx)*tx,sty+(eny-sty)*tx
			local col = sget(sx+sw*tx,sy+sh*ty)
			if (col ~= 0)	pset(dx+px,dy+py,col)
		end
	end
end
__gfx__
0000000007dddd6006dddd700dddddd006dddd707880000088788878887888780000000000000000000000000000000000000000000000000000000000000000
000000000d55567dd76555d00dddddd0d76555d08780000087878787878787870000000000000000000000000000000000000000000000000000000000000000
0070070006555dddddd555600dddddd0ddd555608870000078887888788878880000000000000000000000000000000000000000000000000000000000000000
0007700007ddd7d00d7ddd700dddddd00d7ddd708780000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0007700000d94d0000d49d0000dddd0000d49d007880000000000000000000000000000000000000000000000000000000000000000066555566000000000000
007007000d7446d00d6447d00d6611d00d6447d08780000000000000000000000000000000000000000000000000000000000000066666527566666000000000
00000000006dd700007dd60000616100007dd6008870000000000000000000000000000000000000000000000000000000000000666666572566666600000000
0000000000d00d0000d00d0000d00d0000d00d008780000000000000000000000000000000000000000000000000000000000055666555222255566655000000
00000000000000007000000078787878787878787880000000aaaa0000aaaa0000aaaa0000aaaa00000044000000000000000527565222222222256572500000
0000000000000000800000000000000000000000878000000aa55aa00aa55aa00aa5aaa00aaa5aa0000444400000000000000572252225555552225227500000
000000000009900070000000000000000000000088700000aa5555aaaaa55aaaaa55aaaaaaaa55aa004446400000000000006652222256666665222225660000
00000000009aa90080000000000000000000000087800000a555555aaaa55aaaa555555aa555555a044446400000000000006665222566666666522256660000
00000000009aa90070000000000000000000000078800000aaa55aaaa555555aa555555aa555555a046446400000000000066665225666666666652225666000
000000000009900080000000000000000000000087800000aaa55aaaaa5555aaaa55aaaaaaaa55aa046446400000000000066652256666655666665225666000
0000000000000000700000000000000000000000887000000aa55aa00aa55aa00aa5aaa00aaa5aa0044664400000000000055522256666577566665222555000
00000000000000008000000000000000000000008780000000aaaa0000aaaa0000aaaa0000aaaa0000444400000000000005272225666577e256665222725000
17777777777777777000000000000000000000000000000000aaaa0000aaaa0000aaaa0000aaaa000000440000000000000572222566657e2256665222275000
1711111111111117800000000000000000000000000000000aabbaa00aabbaa00aabaaa00aaabaa0000444400000000000055522256666522566665222555000
176666666666661770000000000000000000000000000000aabbbbaaaaabbaaaaabbaaaaaaaabbaa00444a400000000000066652256666655666665225666000
176666666666661780000000000000000000000000000000abbbbbbaaaabbaaaabbbbbbaabbbbbba04444a400000000000066652225666666666652225666000
177777777777777770000000000000000000000000000000aaabbaaaabbbbbbaabbbbbbaabbbbbba04a44a400000000000006665222566666666522256660000
166666666666666780000000000000000000000000000000aaabbaaaaabbbbaaaabbaaaaaaaabbaa04a44a400000000000006652222256666665222225660000
1666666666666667700000000000000000000000000000000aabbaa00aabbaa00aabaaa00aaabaa0044aa4400000000000000572252225555552225227500000
16666666666666678000000000000000000000000000000000aaaa0000aaaa0000aaaa0000aaaa00004444000000000000000527565222222222256572500000
166666655666666711111111000000006555555600000000166466b6441516471466466646646667177777777777777700000055666555222255566655000000
16666655556666675555d5550000000056766765000000001663bb34615151671646666466666467171111111111111700000000666666527566666600000000
16666555555666675555d555000000005757757500000000163b53b61515151716dddd6646dddd67174666664666661700000000066666572566666000000000
1666655555566667dddddddd00000000567667650000000016b53b366ddddd6716dddd4666dddd67176557766664661700000000000066555566000000000000
166665555556666755d55555000000005676676500000000145b53564ddddd6714dddd6464dddd67176666646666661700000000000000000000000000000000
166665555556666755d55555000000005757757500000000165543b66ddddd4716dddd6666dddd67177777777777777700000000000000000000000000000000
1666655555566667555d555500000000567667650000000016555554655555671664666666666467166664666666666700000000000000000000000000000000
1666655555566667555d555500000000655555560000000016555556656665671646664646466647164666664666646700000000000000000000000000000000
000000000d66d0000011100011111111555555555dddddd50000005d5d0000005dddddd55d555555555555d55555d5555d5555d55d5555d5dd5555d555555555
ddddddddd1111dd0001110001111111155555555dd5555dd0000055d5dd00000dd5555dd5ddd55555555ddd55555d555dddddddddddddddd5d5555d555555555
11111111111111100011100001111100ddddddd5555555550000ddddd555000055555555555dd555555dd5555555d555d555555dd555555d0ddddddd55555555
00000000000001100011100000111000555555dd0555555500055d5d55550000555555555555d555555d5555ddddddddd555555dd55555500055d5d5555ddddd
00000dddddddd1100011100000111000dd5555550005555500555d5d5555550055555550dd55d555555d55dd55d55555d555555dd55555000005d5d555dd5d55
0000d1111111111000111000001110005ddddddd00005555ddddddddd5555550555550005dddddddddddddd555d55555d555555dd55550000000dddd55d55d55
0001111111111110001110000011100055555555000005ddd5d55d555ddddddddd5500005555555dd5555555555d5555dddddddddddd00000000055555d55d55
0001110001110000001110000011100055555555000000d5dddddddddd5555d55dd000005555555dd5555555111111115d5555d55d500000000000dd55d55d55
000110000000000000111000155d555155d55d55555555555555555511111111ddd2dddd55555555555555551666646455555555dd500000000005d566646646
000110000000000000111000155dd55155d55d555551155555a99a5516666661d22dd22d555555dd5ddd555514666666554444555d550000000055d546666666
0001100000000000001110001155d51155dd5dd5dd5665dddda66add16611661d22dd22ddd5555d5dd5d5ddd1466666654544545ddddd000000ddddd64655666
0005500000011100011111001155d511555d55d55d5665d55d5665d516166161dddd2dd25ddd5dd5555d5d5516646466544554455555d5000055d5d566555564
111150000011110001111d001155d511555d55d55dd775d55dd775d5161661612ddddddd555d5d55555d5d5516666666544554455555d5d00555d5d566555546
1111111111111111111ddd00115d551155dd5dd555577dd555577dd516611661d22dd22d555d5d55555ddd551664666654544545dddddddddddddddd46555566
d111dddddddddddddddddd00115d551155d55d55555775555557755516666661d22dd22d555ddd555555555516666466554444555d55d5555d55d55564555566
dddd00000000000000000000155d555155d55d55555775555557755511111111ddd2dddd55555555555555551646666455555555dddddddddddddddd66555564
5555d55500111100001111000011110000111100555555555555555dd55555559999999999999999999999999aaaaaaaaaaaaaa9999999996666611166646641
5555d55511100111111051111110011111160111555665dd5677775dd57777659aaaaaaaaaaaaaaaaaaaaaa99aa9aaaaaa9aaaa9999999996777666146dddd61
55555d5511000011110055111100001111606011dd5665d55671115dd51117659a99aaaaaa9aaa9aa9aa99a99a9aaaa9a9aaa9a9999999996777776166dddd61
55555d55000000000000555000011006060716005d5115d5567555dddd5557659a99aa9aa9aaa9aa9aaa99a99aaaaa9aaaaa9aa9999999996777776164dddd61
55555d55000000000666555000011060606160005d5115d5567dddd55dddd7659aaaa9aaaaaaaaaaaaaaaaa99aaaaaaaaaaaaaa9999999996777776166dddd61
5555d555110000111166651111000607060600115d5775d5dd675555555576dd9aaaaaaaaaaa9aaaaaaaa9a99aaa9aaaaaa9aaa9999999996667776166464661
5555d555111001111116611111100160611001115dd775d5d56755555555765d9aaaa9aaaaa9aaaaaa9aaaa99aa9aaaaaa9aaaa9999999996766666146666461
5555d5550011110000111100001111060011110055577dd5d56755555555765d9aaa9aaaaaaaaaaaaaaaaaa99aaaaaaaaaaaaaa9999999996761676166646661
0001110000111100001110000011160000161100555555555555555dd55555559aaaaaaaaaaaaaaaaaaaaaa999999999aaaaaaaa999999991116666611111111
0011111111100111111111001110606111666111555665dd5677775dd57777659aaa9aaaaaaaaa9aaa9aaaa99a9aa9a9aaaaaaaa999999991666777655555555
0111001111000011110011101106070616606611dd5665d5567999adda9997659aa9aaaaaa9aa9aaaaa9aaa999aaaa99aaaaaaaa999999991677777655555555
11100000000110000000011100006060660706605d5995d5567aaaddddaaa7659aaaaaaaa9aaaaaaaaaaaaa99aa99aa9aaaaaaaa9999999916777776ddd55ddd
11100000000110000000011100000600066066005da99ad5567dddd55dddd7659a99aa9aaaaaa9aaa9aa99a99aa99aa9aaaaaaaa999999991677777655dddd55
01110011110000111100111011000011116661115daaaad5dd675555555576dd9a99a9aaaaaa9aaaaaaa99a999aaaa99aaaaaaaa999999991677766655555555
00111111111001111111110011100111111611115dd775d5d56755555555765d9aaaaaaaaaaaaaaaaaaaaaa99a9aa9a9aaaaaaaa999999991666667655555555
000111000011110000111000001111000011110055577dd5d56755555555765d99999999999999999999999999999999aaaaaaaa999999991676167611111111
177777777777777716666666666666670000044444411151000004444444dd51000004444444dd11001114444444dd11000004419914dddd0000044444411151
1711111111111117166666666666666700044ddddd19991d00044dddddddd51d00044dddddddd51d019991ddddddd11d00044d19a91ddddd00044ddddd19991d
176666666666661716dddd6666dddd67004ddddddd19a914004ddddddddd51d4004ddddddddd51d4019a91dddddd51d4004ddd19991dddd4004ddddddd19a914
176557766666661716dddd6666dddd6704dddd444419994004dddd4444dd1d4004dddd4444dd1d400199914444dd1d4004dddd1661dddd4004dddd4444199940
176666666666661716dddd6666dddd6704dd44444166114004dd44444444dd4004dd44444444dd40041166144444dd4004dd44166144dd4004dd444441661140
177777777777777716dddd6666dddd674ddd44551661ddd44ddd44555544ddd44ddd44555544ddd44ddd16615544ddd44ddd44166144ddd44ddd44551661ddd4
166666666666666716666666666666674dd4455166144dd44dd4451115544dd44dd4455111544dd44dd4416615544dd44dd4451661544dd44dd4455166144dd4
166666666666666716666666666666674dd4451661544dd44dd4451661544dd44dd4451661544dd44dd4451661544dd44dd4451661544dd44dd4451661544dd4
577777777777777716666666661516674dd4451661544dd44dd4451661544dd44dd4416661544dd44dd4451661544dd44dd4451661544dd44dd4451661544dd4
575555555555555716655566615151674dd4451115544dd44dd4455166144dd44dd4166115544dd44dd4455115544dd44dd4455115544dd44dd4451115544dd4
576666666666665716555556151515174dd1445555441dd44dd1445516611dd44d11661555441dd44dd1445555441dd44dd1445555441dd44dd1445555441dd4
5766666666656657165555566ddddd6704dd44444444dd4004dd444441661140019991444444dd4004dd44444444dd4004dd44444444dd4004dd44444444dd40
5765555555555657165555566ddddd6704dd11444411dd4004dd114444199910019a91444411dd4004dd11444411dd4004dd11444411dd4004dd11444411dd40
5766666666656657165555566ddddd67004ddd1111ddd400004ddd111119a9100199911111ddd400004ddd1111ddd400004ddd1111ddd400004ddd1111ddd400
5766666666666657165555566555556700044dddddd4400000044ddddd19991000111dddddd4400000044dddddd4400000044dddddd4400000044dddddd44000
57777777777777771655555665666567000004444440000000000444444111000000044444400000000004444440000000000444444000000000044444400000
57777777777777777777777757777777777777777777777766666666666666665666666666666667111111111666666716466667177777770666666666666660
575555555555555555555557575555555555555555555557655555555555555656666d6666d6666711111111146dd6471663b667171111170666666666666660
57666666666666666666665757666666666666666666665765556666666655565666ddd66ddd66671111111116dddd67163bbb67176646170666555555556660
57666666666655776666665757666666666655776666665765566666666665565666ddd66ddd66671111111116dddd6714b3b367176466170666666666666660
5766666666666666666666575766666666666666666666576566666666666656566666666666666711111111166dd667165b5b47177777770666666666666660
577777777777777777777777577777777777777777777777656666666666665656666d6666d666671111111116646667165b5567164666470666666555556660
56666666666666666666666756666666666666666666666765666666666666565666ddd66ddd6667111111111466664716555547166646670666555556666660
56666666666666666666666756666666666666666666666765666775566666565666ddd66ddd6667111111111666466716555567164666670666666666666660
56666666666666666666666756666666666666666666666765666775566666565666666666666667156666566566661111666656656666510666666666666660
566ddd6ddd666555556666675666665555566666dddddd6765666666666666565666666666666667156666555566661111666655556666510666555555556660
566ddd6ddd665555555666675666655555556666dddddd6765666666666666565666665555666667156777666566661111666656667776510666566666666660
566ddd6ddd665555555666675666655555556666dddddd6765666666666666565666655555566667157676755666561111656665576767510666666666666660
5666666666665555555666675666655555556666dddddd6765566666666665565666655555566667157676766665d511115d5666676767510666666666666660
56666666666655555556666756666555555566666666666765556666666655565666655555566667156777666665d511115d5666667776510666555555556660
56666666666655555556666756666555555566666666666765555555555555565666655555566667156666666666661111666666666666510666665555666660
56666666666655555556666756666555555566666666666766666666666666665666655555566667155555555555551111555555555555510666666666666660
1111111111112252252211111111111100000000000022522522000000000000177777777f7777777777f77717777777777f7777666666666666666600000000
11111111122222222222222111111111000000000222222222222420000000001711111111111111111111171711111111111117611111111111111600000000
1111111d2222222222222222d1111111000000042244224222422222400000001f66644666666666666644171f46666666466617611166666466111600000000
111111dd2222dddddddd2222dd11111100000044222244444444222244000000176446666466117766644617176646646661661f61166646666661160000aaaa
11111ddd2ddd66555566ddd2ddd111110000045424446655556644424540000017666666444666666666661f176111411111461761664666466466160000000a
1111ddddd66666527566666ddddd111100004544466666527566666444440000177777777777f7777777777717646664666166176146646666666416000000aa
111ddddd6666665725666666ddddd111000455446666665725666666444540001646666666663463646366b71766666646666417616666646466661600000000
1122dd55666555222255566655dddd110022445566655522225556665545440016666466446633633646bb6717777777f7777777616467711664661600000000
1122d5275652222222222565725d22110022452756522222422225657254220016466666666463b66b6636671666666666666667616667711666461611111111
1222d5722522255555522252275d222102224572252245555552245227542420166ddd6ddd6464b3b3bb666716646d6646d66467616664666666661655556676
122d665222225666666522222566d22102246654224256666665222225664420166ddd6ddd6655b53b5664671666ddd64ddd6667616466646646461655656086
122d666522256666666652225666d22104246665222566666666542256664220166ddd6ddd665b55b556664f1646ddd66ddd4667616666464666661667666806
22d66665225666666666652225666d2222466665225666666666652425666422166646666646535453564667166666666666466f611666666666611656767006
22d66652256666655666665225666d222246665224666665566666522566642216466464666653555556646716646d6646d66667611164646646111666666067
52d55522256666577566665222555d25524555222566665745666654225554251666666666464555455664471646ddd66ddd6667611111111111111655657666
22d5272225666577e256665222725d222245272425666574e2566652227254221646666446664455555446671646ddd64ddd664f666666666666666611111111
22d572222566657e2256665222275d22224572222566657e4246665242275422177777f77777777777f777771666666666666667111111111111111111111111
22d55522256666522566665222555d2222455522256666522464665242555422171111111111111111111117164664b666466467116666666666664666466611
52d66652256666655666665225666d25524666522566666554446652256664251766666666666666664666171464665bb566666f166666466646666666666661
22d66652225666666666652225666d22224666524256666666464524256664221f6446466466117764666417166665334b566467164666117766666666646661
222d666522256666666652225666d2222224666522256666666652225666422217666666666666664646661716446b3b33566667166666117766646466666661
122d665222225666666522222566d22102246652222256666665422225664220177777f77777f77777777777166665b33b564667166466466666666664664661
1222d5722522255555522252275d22210422457225424555555222522754222016646666466666466646666f1666645535566667116666666646666666666611
1122d5275652222222222565725d2211002245275652222242222565725422001646646644646664646664671664655555466647111111111111111111111111
11dddd55666555222255566655dddd1100444455666555222255566655444400166646646666646666464667177777f77f77777f1646666bb664666f55555555
111ddddd6666665275666666ddddd111000545546666665275666666444540001644665555466646dddddd671f11111111111117166646535b64646755556676
1111ddddd66666572566666ddddd1111000044444666665725666664454400001666455555546666dddddd671766466666666617164663b33556666f55656086
11111ddd2ddd66555566ddd2ddd11111000004542444665555664442445000001646654545554646dddddd6717646664666666171466645b3b36466776766806
111111dd2222dddddddd2222dd111111000000442222444444442222445000001666655555556466dddddd67177f7777777f777716646543b3566647d6676007
1111111d2222222222222222d111111100000004222222242222222240000000166665545545664664666467166666646666666f166665535556466766666066
11111111122222222222222111111111000000000242222224222220000000001646455545554664666464671644666666666667166465553556666f55756676
11111111111122522522111111111111000000000000225224220000000000001666654555556466464666471466666666666667166665555556664755555555
__label__
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
88888777777888eeeeee888eeeeee888eeeeee888eeeeee888eeeeee888888888888888888888888888ff8ff8888228822888222822888888822888888228888
8888778887788ee88eee88ee888ee88ee888ee88ee8e8ee88ee888ee88888888888888888888888888ff888ff888222222888222822888882282888888222888
888777878778eeee8eee8eeeee8ee8eeeee8ee8eee8e8ee8eee8eeee88888e88888888888888888888ff888ff888282282888222888888228882888888288888
888777878778eeee8eee8eee888ee8eeee88ee8eee888ee8eee888ee8888eee8888888888888888888ff888ff888222222888888222888228882888822288888
888777878778eeee8eee8eee8eeee8eeeee8ee8eeeee8ee8eeeee8ee88888e88888888888888888888ff888ff888822228888228222888882282888222288888
888777888778eee888ee8eee888ee8eee888ee8eeeee8ee8eee888ee888888888888888888888888888ff8ff8888828828888228222888888822888222888888
888777777778eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee8eeeeeeee888888888888888888888888888888888888888888888888888888888888888888888888
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111111111666166116661666117111711111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111161161611611161171111171111111111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111111111161161611611161171111171111111111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111161161611611161171111171111111111111111111111111111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661666161616661161117111711111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111166616661111111111111ccc11111cc11c1c1cc11ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111
111116161161111117771111111c111111c11c1c11c11c1111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666116111111111111111cc111111c11ccc11c11ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111
111116111161111117771111111c111111c1111c11c1111c11111111111111111111111111111111111111111111111111111111111111111111111111111111
1111161116661111111111111ccc11c11ccc111c1ccc1ccc11111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666161116661616166616661111166616611666166611711171111111111111111111111111111111111111111111111111111111111111111111111111
11111616161116161616161116161111116116161161116117111117111111111111111111111111111111111111111111111111111111111111111111111111
11111666161116661666166116611111116116161161116117111117111111111111111111111111111111111111111111111111111111111111111111111111
11111611161116161116161116161111116116161161116117111117111111111111111111111111111111111111111111111111111111111111111111111111
11111611166616161666166616161666166616161666116111711171111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111166616661661166611661666166616661111111111111ccc1ccc1c1111cc1ccc111111111111111111111111111111111111111111111111111111111111
1111166611611616116116111616166616111111177711111c111c1c1c111c111c11111111111111111111111111111111111111111111111111111111111111
1111161611611616116116111666161616611111111111111cc11ccc1c111ccc1cc1111111111111111111111111111111111111111111111111111111111111
1111161611611616116116161616161616111111177711111c111c1c1c11111c1c11111111111111111111111111111111111111111111111111111111111111
1111161616661616166616661616161616661111111111111c111c1c1ccc1cc11ccc111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111666166616611666116616661666166611111666161616661666166616661111111111111ccc111111111111111111111111111111111111111111111111
11111666116116161161161116161666161111111616161616111611161116161111177711111c1c111111111111111111111111111111111111111111111111
11111616116116161161161116661616166111111661161616611661166116611111111111111c1c111111111111111111111111111111111111111111111111
11111616116116161161161616161616161111111616161616111611161116161111177711111c1c111111111111111111111111111111111111111111111111
11111616166616161666166616161616166616661666116616111611166616161111111111111ccc111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116661166116611661111111111111cc11ccc1c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116161616161116111111177711111c1c11c11c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116611616166616661111111111111c1c11c11c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116161616111611161111177711111c1c11c11c11111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111116661661166116611111111111111c1c1ccc1ccc111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111166611661166116611111111111116111166166616611111166611661166116611711c111ccc11111c111ccc117111111111111111111111111111111111
1111161616161611161111111777111116111616161616161111161616161611161117111c11111c11111c11111c111711111111111111111111111111111111
1111166116161666166611111111111116111616166616161111166116161666166617111ccc11cc11111ccc11cc111711111111111111111111111111111111
1111161616161116111611111777111116111616161616161111161616161116111617111c1c111c11711c1c111c111711111111111111111111111111111111
1111166616611661166111111111111116661661161616661666166616611661166111711ccc1ccc17111ccc1ccc117111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1111116611661666161111111661161616661111111111111cc11ccc1ccc11111111111111111111111111111111111111111111111111111111111111111111
11111611161611611611111116161616166611111777111111c1111c111c11111111111111111111111111111111111111111111111111111111111111111111
11111611161611611611111116161616161611111111111111c111cc1ccc11111111111111111111111111111111111111111111111111111111111111111111
11111611161611611611111116161616161611111777111111c1111c1c1111111111111111111111111111111111111111111111111111111111111111111111
1111116616611666166616661616116616161111111111111ccc1ccc1ccc11111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111661666166616661111166616611166161116661111111111111ccc11111111111111111111111111111111111111111111111111111111111111111111
111116111611161616161111161616161611161116111111177711111c1c11111111111111111111111111111111111111111111111111111111111111111111
111116111661166616611111166616161611161116611111111111111c1c11111111111111111111111111111111111111111111111111111111111111111111
111116161611161616161111161616161616161116111111177711111c1c11111111111111111111111111111111111111111111111111111111111111111111
111116661666161616161666161616161666166616661111111111111ccc11111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111166166616661666111111661666166616661661111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111611161116161616111116111616161116111616111117771111111111111111111111111111111111111111111111111111111111111111111111111111
11111611166116661661111116661666166116611616111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111616161116161616111111161611161116111616111117771111111111111111711111111111111111111111111111111111111111111111111111111111
11111666166616161616166616611611166616661666111111111111111111111111771111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111777111111111111111111111111111111111111111111111111111111111
1eee1ee11ee111111111111111111111111111111111111111111111111111111111777711111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111771111111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e11111111111111111111111111111111111111111111111111111111117111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1eee11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
1eee1e1e1ee111ee1eee1eee11ee1ee1111111111616166616611666166616661171117111111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161616161616116116111711111711111111111111111111111111111111111111111111111111111111
1ee11e1e1e1e1e1111e111e11e1e1e1e111111111616166616161666116116611711111711111111111111111111111111111111111111111111111111111111
1e111e1e1e1e1e1111e111e11e1e1e1e111111111616161116161616116116111711111711111111111111111111111111111111111111111111111111111111
1e1111ee1e1e11ee11e11eee1ee11e1e111116661166161116661616116116661171117111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
111111111111111111dd1ddd1ddd11111ddd1ddd1ddd11dd1ddd1ddd11111ddd11dd1ddd11111d1d11dd11dd1d1d111111111111111111111111111111111111
11111111111111111d111d1111d1111111d11d1d1d1d1d111d1111d111111d111d1d1d1d11111d1d1d1d1d1d1d1d111111111111111111111111111111111111
11111ddd1ddd11111d111dd111d1111111d11ddd1dd11d111dd111d111111dd11d1d1dd111111ddd1d1d1d1d1dd1111111111111111111111111111111111111
11111111111111111d1d1d1111d1111111d11d1d1d1d1d1d1d1111d111111d111d1d1d1d11111d1d1d1d1d1d1d1d111111111111111111111111111111111111
11111111111111111ddd1ddd11d1111111d11d1d1d1d1ddd1ddd11d111111d111dd11d1d11111d1d1dd11dd11d1d111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111
11111eee1eee1111166611661166116611111eee1e1e1eee1ee11111111111111111111111111111111111111111111111111111111111111111111111111111
111111e11e1111111616161616111611111111e11e1e1e111e1e1111111111111111111111111111111111111111111111111111111111111111111111111111
111111e11ee111111661161616661666111111e11eee1ee11e1e1111111111111111111111111111111111111111111111111111111111111111111111111111
111111e11e1111111616161611161116111111e11e1e1e111e1e1111111111111111111111111111111111111111111111111111111111111111111111111111
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888
82888222822882228888822882228882822282228888888888888888888888888888888888888888888882228222822282828882822282288222822288866688
82888828828282888888882888828828888282888888888888888888888888888888888888888888888888828282888282828828828288288282888288888888
82888828828282288888882888228828888282228888888888888888888888888888888888888888888882228222882282228828822288288222822288822288
82888828828282888888882888828828888288828888888888888888888888888888888888888888888882888282888288828828828288288882828888888888
82228222828282228888822282228288888282228888888888888888888888888888888888888888888882228222822288828288822282228882822288822288
88888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888888

__gff__
0000000000000000000000000080800000000000000000000000000080000080000000000000000000000000800000800000000000000000000000000080800000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000808000008080000000000000000000800000808000008000000000000000008000008080000080000000000000000000808000008080000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c5c5c5c5c686a5c5c5c5c5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c5c5c5c5c6b6c5c5c5c5c5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c5c5c5c7b787a7b5c5c5c5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c5c5c7b7b686a7b7b5c5c5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c7b7b7b436b6c727b7b7b5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c7b7372426b6c6364727b5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c7b7b505152787a7374627b7b5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000068696a6869696a686a6869696a68696a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000078797a7879797a787a7879797a78797a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c7b7b737462686a6163647b7b5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c7b7363646b6c7374727b5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c7b7b7b706b6c727b7b7b5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c5c5c7b7b787a7b7b5c5c5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c5c5c5c7b686a7b5c5c5c5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c5c5c5c5c6b6c5c5c5c5c5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005c5c5c5c5c5c5c787a5c5c5c5c5c5c5c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000057575757575757545457575757575757000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000057fbfcc8c9ca665454675b5f6fcdce57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000057fdfed8d9da4954544a7f7fdfddde57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000057df7f327f7f4a545467edeeefcbcc57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000057fbfc53cbcc4954544ae8e9eadbdc57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000057fdfe53fdfe664d4e67f8f9faebec57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555a655a655ac0c1c2c35a655a655a65000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000444444ff444dd0d1d2d34e4444444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000044444444445de0e1e2e35e44ff444444000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000555955595559f0f1f2f3595559555955000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000057575753cdce665d5e67ad5757cbcc57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000573a3b53ddde4954544aabfbfcdbdc57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000057383953fbfc66545467acfdfeebec57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000057363753fdfe4954544a7f7f7f7fdf57000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000577f7f4b7f7f4a545467575757575757000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000057575757575757545457575757575757000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100000000000000000000000000000000002a0502d0502f050000002f0502f050280502305021050200502005021050000002405026050280502a050000000000000000000000000000000000000000000000
