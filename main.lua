local log =
    require "https://raw.githubusercontent.com/ccheever/castle-utils/c5a150bf783bfcaf24bbcf8cbe0824fae34a8198/log.lua"
local array =
    require "https://raw.githubusercontent.com/ccheever/castle-utils/81e0e1e92fff19a8aa597bbed7939fc2ef048562/array.lua"

local GameState
local Score
local Level
local Rows
local CurrentPiece
local NextPiece
local CPColor = {0.3, 0.8, 0.3, 1.0}
local CPX
local CPY
local Board
local UserAvatarImage
local UserId
local User

local BoardWidth = 10
local BoardHeight = 24
local HiddenRows = 4

local Pieces = {
    {"rod", {{2, 1}, {2, 2}, {2, 3}, {2, 4}}, {0.0, 0.0, 1.0, 1.0}},
    {"square", {{2, 2}, {2, 3}, {3, 2}, {3, 3}}, {1.0, 0.0, 0.0, 1.0}},
    {"J", {{1, 2}, {1, 3}, {2, 3}, {3, 3}}, {1.0, 2 / 3, 0.0, 1.0}},
    {"L", {{1, 2}, {2, 2}, {3, 2}, {1, 3}}, {1.0, 0.0, 1.0, 1.0}},
    {"T", {{1, 2}, {2, 2}, {3, 2}, {2, 3}}, {0.0, 1.0, 0.0, 1.0}}
}

love.keyboard.setKeyRepeat(true)

function colorFromHex(s)
    local rh = s:sub(2, 3):lower()
    local gh = s:sub(4, 5):lower()
    local bh = s:sub(6, 7):lower()
end

function initGameState()
    Board = {}
    for x = 1, BoardWidth do
        local a = {}
        for y = 1, BoardHeight do
            table.insert(a, 0)
        end
        table.insert(Board, a)
    end

    Board = array.createArray({BoardWidth, BoardHeight}, 0)
    Level = 1
    CPX = 5
    CPY = 0
    Score = 0
    Rows = 0
    NextPiece = Pieces[love.math.random(#Pieces)]
    startNextPiece()
end

function setCurrentPiece(piece)
    CurrentPiece = {
        {0, 0, 0, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    }

    CPColor = piece[3]

    for _, p in ipairs(piece[2]) do
        local x, y = unpack(p)
        CurrentPiece[x][y] = 1
    end

    return CurrentPiece
end

function love.load()
    GameState = "TITLE_SCREEN"
    initGameState()
    network.async(
        function()
            User = castle.user.getMe()
            UserId = User.userId
            UserAvatarImage = love.graphics.newImage(User.photoUrl)
            GameState = "IN_GAME"
            -- log({UserName = UserName, UserAvatarImage = UserAvatarImage})
            log({UserId = UserId, UserAvatarImage = UserAvatarImage, User = User})
        end
    )
end

function rotateCurrentPieceRight()
    local newPiece = {{}, {}, {}, {}}
    for x = 1, 4 do
        for y = 1, 4 do
            newPiece[y][x] = CurrentPiece[x][5 - y]
        end
    end
    CurrentPiece = newPiece
    return CurrentPiece
end

function rotateCurrentPieceLeft()
    local newPiece = {{}, {}, {}, {}}
    for x = 1, 4 do
        for y = 1, 4 do
            newPiece[y][x] = CurrentPiece[5 - x][y]
        end
    end
    CurrentPiece = newPiece
    return CurrentPiece
end

function checkCurrentPieceLocationValid()
    for x = 1, 4 do
        for y = 1, 4 do
            if CurrentPiece[x][y] > 0 then
                local x_ = CPX - 1 + x
                local y_ = CPY - 1 + y
                if x_ < 1 or x_ > BoardWidth or y_ < 1 or y_ > BoardHeight or Board[x_][y_] ~= 0 then
                    return false
                end
            end
        end
    end
    return true
end

function drawBoard(x, y, s)
    local bw = 2
    love.graphics.setColor(0.8, 0.8, 0.8, 0.4)
    love.graphics.setLineWidth(s)
    love.graphics.rectangle("line", x, y, BoardWidth * s, (BoardHeight - HiddenRows) * s)
    love.graphics.setLineWidth(0)
    love.graphics.setColor(0, 0, 0, 1)
    love.graphics.rectangle("fill", x, y, BoardWidth * s, (BoardHeight - HiddenRows) * s)
    for row = 1 + HiddenRows, BoardHeight do
        for col = 1, BoardWidth do
            local block = Board[col][row]
            local x_ = x + s * (col - 1)
            local y_ = y + s * (row - HiddenRows - 1)
            if block ~= 0 then
                love.graphics.setColor(unpack(block[1]))
                love.graphics.setLineWidth(bw)
                love.graphics.rectangle("fill", x_ + bw / 2, y_ + bw / 2, s - bw, s - bw)
                local ah = UserAvatarImage:getHeight()
                local aw = UserAvatarImage:getWidth()
                love.graphics.draw(UserAvatarImage, x_ + bw / 2, y_ + bw / 2, 0, (s - bw) / aw, (s - bw) / ah)

                love.graphics.setColor(unpack(block[1]))
                love.graphics.setColor(0.3, 0.6, 0.9, 0.8)
                -- love.graphics.setColor(1.0, 0.8, 0.0, 1.0)
                love.graphics.setLineWidth(bw)
            else
                love.graphics.setColor(0.2, 0.2, 0.2, 0.1)
                love.graphics.setLineWidth(1)
            end
            love.graphics.rectangle("line", x_, y_, s, s)
        end
    end

    -- Draw current piece
    for cx = 1, 4 do
        for cy = 1, 4 do
            local gx = cx + CPX - 1
            local gy = cy + CPY - 1
            local x_ = x + s * (gx - 1)
            local y_ = y + s * (gy - HiddenRows - 1)
            if gx > 0 and gx <= BoardWidth and gy >= HiddenRows and gy <= BoardHeight and CurrentPiece[cx][cy] > 0 then
                love.graphics.setColor(unpack(CPColor))
                love.graphics.setLineWidth(3)
                love.graphics.rectangle("line", x_, y_, s, s)
            end
        end
    end
end

function love.draw()
    if GameState == "TITLE_SCREEN" then
        love.graphics.print("QUADRAX", 20, 20)
        love.graphics.print("Press any key to start", 20, 40)
    elseif GameState == "IN_GAME" then
        -- love.graphics.draw(UserAvatarImage, 0, 0, 0)
        love.graphics.print("QUADRAX", 20, 20)
        love.graphics.print("Level " .. Level, 20, 50)
        love.graphics.print("Score " .. Score, 20, 80)
        love.graphics.print("Rows  " .. Rows, 20, 110)

        love.graphics.print("Next", 20, 170)
        drawPiece(NextPiece, 20, 180)
        drawBoard(150, 0, 22)
    elseif GameState == "GAME_OVER" then
        love.graphics.print("GAME OVER", 20, 20)
        love.graphics.print("Level " .. Level, 20, 50)
        love.graphics.print("Score " .. Score, 20, 80)
        love.graphics.print("Rows  " .. Rows, 20, 110)
    -- love.graphics.print("Press a key to start again", 20, 40)
    end
end

local t = 0
function love.update(dt)
    local t_ = t + dt
    local int = Level * 0.7
    if math.floor(t * int) ~= math.floor(t_ * int) then
        movePieceDown()
    end
    t = t_
end

function movePieceDown()
    CPY = CPY + 1
    if checkCurrentPieceLocationValid() then
        Score = Score + 1
        return true
    else
        CPY = CPY - 1
        placePiece()
        startNextPiece()
        return false
    end
end

function placePiece()
    for x = 1, 4 do
        for y = 1, 4 do
            if CurrentPiece[x][y] > 0 then
                Board[CPX + x - 1][CPY + y - 1] = {CPColor, "whoami"}
            end
        end
    end
    checkAndClearRows()
end

function checkAndClearRows()
    local rows_ = Rows
    local removedRows = 0
    local inc = 0
    for y = 1, BoardHeight do
        local noHoles = true
        for x = 1, BoardWidth do
            if not (Board[x][y] ~= 0) then
                noHoles = false
                break
            end
        end
        if noHoles then
            removedRows = removedRows + 1

            -- Get increasing amounts of points for
            -- removing multiple rows at at time
            inc = inc + 100
            Score = Score + inc
            Rows = Rows + 1

            -- Remove row
            for y_ = y, 2, -1 do
                for x_ = 1, BoardWidth do
                    Board[x_][y_] = Board[x_][y_ - 1]
                end
            end
            for x_ = 1, BoardWidth do
                Board[x_][1] = 0
            end
        end
    end
    if (math.floor(rows_ / 10) ~= math.floor(Rows / 10)) then
        Level = Level + 1
    end
end

function startNextPiece()
    setCurrentPiece(NextPiece)
    NextPiece = Pieces[love.math.random(#Pieces)]
    CPX = 4
    CPY = 1
    if not checkCurrentPieceLocationValid() then
        gameOver()
    end
end

function gameOver()
    GameState = "GAME_OVER"
end

function drawPiece(p, x, y)
    local color = p[3]
    local pieceName = p[1]
    local blocks = p[2]
    for _, block in ipairs(blocks) do
        love.graphics.setColor(color[1], color[2], color[3], color[4])
        love.graphics.setLineWidth(3)
        local px = block[1]
        local py = block[2]
        local size = 20
        love.graphics.rectangle("line", x + px * size, y + py * size, size, size)
    end
end

function love.keypressed(key, scancode, isrepeat)
    if GameState == "TITLE_SCREEN" then
        GameState = "IN_GAME"
    elseif GameState == "GAME_OVER" then
        initGameState()
        GameState = "IN_GAME"
    elseif GameState == "IN_GAME" then
        if key == "r" or key == "up" then
            rotateCurrentPieceRight()
            if not checkCurrentPieceLocationValid() then
                rotateCurrentPieceLeft()
            end
        elseif key == "l" then
            rotateCurrentPieceLeft()
            if not checkCurrentPieceLocationValid() then
                rotateCurrentPieceRight()
            end
        elseif key == "left" then
            CPX = CPX - 1
            if not checkCurrentPieceLocationValid() then
                CPX = CPX + 1
            end
        elseif key == "right" then
            CPX = CPX + 1
            if not checkCurrentPieceLocationValid() then
                CPX = CPX - 1
            end
        elseif key == "down" then
            movePieceDown()
        elseif key == "space" then
            while movePieceDown() do
            end
        elseif key == "p" then
            setCurrentPiece(Pieces[love.math.random(#Pieces)])
        end
    end
end
