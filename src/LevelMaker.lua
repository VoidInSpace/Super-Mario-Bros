--[[
    GD50
    Super Mario Bros. Remake

    -- LevelMaker Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

LevelMaker = Class{}

CollectedKey = false        

function LevelMaker.generate(width, height)
    local tiles = {}
    local entities = {}
    local objects = {}

    local tileID = TILE_ID_GROUND
    
    -- whether we should draw our tiles with toppers
    local topper = true
    local tileset = math.random(20)
    local topperset = math.random(20)

    -- variables for the keys and lock's characteristics
    local KeyPos = math.random(width)
    local LockPos = math.random(width)
    local LocksKeysColor = math.random(4)

    -- insert blank tables into tiles for later access
    for x = 1, height do
        table.insert(tiles, {})
    end

    -- column by column generation instead of row; sometimes better for platformers
    for x = 1, width do
        local tileID = TILE_ID_EMPTY
        
        -- lay out the empty space
        for y = 1, 6 do
            table.insert(tiles[y],
                Tile(x, y, tileID, nil, tileset, topperset))
        end

        -- chance to just be emptiness
        -- to avoid the character to land in a chasm on the start
        -- to avoid the key and lock to be placed above a chasm
        if math.random(7) == 1 and x ~= 1 and x ~= KeyPos and x ~= LockPos then
            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, nil, tileset, topperset))
            end
        else
            tileID = TILE_ID_GROUND

            -- height at which we would spawn a potential jump block
            local blockHeight = 4

            for y = 7, height do
                table.insert(tiles[y],
                    Tile(x, y, tileID, y == 7 and topper or nil, tileset, topperset))
            end

            -- chance to generate a pillar
            -- to avoid lock above a pillar
            if math.random(8) == 1 and x ~= LockPos then
                blockHeight = 2
                
                -- chance to generate bush on pillar
                if math.random(8) == 1 then
                    table.insert(objects,
                        GameObject {
                            texture = 'bushes',
                            x = (x - 1) * TILE_SIZE,
                            y = (4 - 1) * TILE_SIZE,
                            width = 16,
                            height = 16,
                            
                            -- select random frame from bush_ids whitelist, then random row for variance
                            frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                            collidable = false
                        }
                    )
                end
                
                -- pillar tiles
                tiles[5][x] = Tile(x, 5, tileID, topper, tileset, topperset)
                tiles[6][x] = Tile(x, 6, tileID, nil, tileset, topperset)
                tiles[7][x].topper = nil
            
            -- chance to generate bushes
            elseif math.random(8) == 1 then
                table.insert(objects,
                    GameObject {
                        texture = 'bushes',
                        x = (x - 1) * TILE_SIZE,
                        y = (6 - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,
                        frame = BUSH_IDS[math.random(#BUSH_IDS)] + (math.random(4) - 1) * 7,
                        collidable = false
                    }
                )
            end

            -- chance to spawn a block
            if math.random(10) == 1 and x ~= LockPos then
                table.insert(objects, 

                    -- jump block
                    GameObject {
                        texture = 'jump-blocks',
                        x = (x - 1) * TILE_SIZE,
                        y = (blockHeight - 1) * TILE_SIZE,
                        width = 16,
                        height = 16,

                        -- make it a random variant
                        frame = math.random(#JUMP_BLOCKS),
                        collidable = true,
                        hit = false,
                        solid = true,

                        -- collision function takes itself
                        onCollide = function(obj)

                            -- spawn a gem if we haven't already hit the block
                            if not obj.hit then
                                
                                -- chance to spawn gem, not guaranteed
                                if math.random(5) == 1 then

                                    -- maintain reference so we can set it to nil
                                    local gem = GameObject {
                                        texture = 'gems',
                                        x = (x - 1) * TILE_SIZE,
                                        y = (blockHeight - 1) * TILE_SIZE - 4,
                                        width = 16,
                                        height = 16,
                                        frame = math.random(#GEMS),
                                        collidable = true,
                                        consumable = true,
                                        solid = false,

                                        -- gem has its own function to add to the player's score
                                        onConsume = function(player, object)
                                            gSounds['pickup']:play()
                                            player.score = player.score + 100
                                        end
                                    }
                                    
                                    -- make the gem move up from the block and play a sound
                                    Timer.tween(0.1, {
                                        [gem] = {y = (blockHeight - 2) * TILE_SIZE}
                                    })
                                    gSounds['powerup-reveal']:play()

                                    table.insert(objects, gem)
                                end

                                obj.hit = true
                            end

                            gSounds['empty-block']:play()
                        end
                    }
                )

            -- to spawn the key
            elseif x == KeyPos then

                local key = GameObject {
                    texture = 'locks-keys',
                    x = (x - 1) * TILE_SIZE,
                    y = (blockHeight + 1) * TILE_SIZE,
                    width = 16,
                    height = 16,
                    frame = LocksKeysColor, 
                    collidable = true,
                    consumable = true,
                    solid = false,

                    onConsume = function(player, object)
                        gSounds['pickup']:play()
                        CollectedKey = true
                    end
                }
                table.insert(objects, key)

            -- to spawn the lock
            elseif x == LockPos then 

                local lock = GameObject {
                    texture = 'locks-keys',
                    x = (width - 2)* TILE_SIZE,--change the x-position of block,
                    y = (blockHeight - 1) * TILE_SIZE,
                    width = 16,
                    height = 16,
                    frame = LocksKeysColor + 4,
                    collidable = true,
                    hit = false,
                    solid = true,
                
                    onCollide = function(obj)
                        if not obj.hit then
                            if CollectedKey then
                                gSounds['pickup']:play()
                                obj.hit = true
                                
                                -- to spawn the post
                                local post = GameObject {
                                    texture = 'posts',
                                    x = obj.x - 1, 
                                    y = (blockHeight - 4) * TILE_SIZE,
                                    width = 12,
                                    height = 48,
                                    frame = 1,
                                    collidable = true,
                                    consumable = true,
                                    solid = false,

                                    onConsume = function(player, object)
                                        gSounds['pickup']:play()

                                        gStateMachine:change('play',
                                        
                                        {width = width + 50, score = player.score} )--update score
                                    end
                                }

                                -- to spawn the flag
                                local flag = GameObject {
                                    texture = 'flags',
                                    x = obj.x + 6,
                                    y = (blockHeight - 2) * TILE_SIZE,
                                    width = 16,
                                    height = 10,
                                    frame = 7,
                                    collidable = true,
                                    consumable = true,
                                    solid = false,

                                    onConsume = function(player, object)
                                        gSounds['pickup']:play()
                                    end
                                }

                                Timer.tween(1.0, {
                                    [flag] = {y = (blockHeight - 4) * TILE_SIZE + 4}
                                })

                                gSounds['powerup-reveal']:play()
                                
                                table.insert(objects, post)
                                table.insert(objects, flag)
                            end 
                        end

                        gSounds['empty-block']:play()
                    end
                }
                table.insert(objects, lock)
            end
        end
    end

    local map = TileMap(width, height)
    map.tiles = tiles
    
    return GameLevel(entities, objects, map)
end