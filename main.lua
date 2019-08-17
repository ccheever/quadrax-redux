local log =
    require "https://raw.githubusercontent.com/ccheever/castle-utils/c5a150bf783bfcaf24bbcf8cbe0824fae34a8198/log.lua"
local array = require "./array"

local GameState
local Level
local CurrentPiece
local CPColor = {0.3, 0.8, 0.3, 1.0}
local CPX
local CPY

local BoardWidth = 10
local BoardHeight = 24
local HiddenRows = 4

local Pieces = {
    {"rod", {{2, 1}, {2, 2}, {2, 3}, {2, 4}}},
    {"square", {{2, 2}, {2, 3}, {3, 2}, {3, 3}}},
    {"J", {{1, 2}, {1, 3}, {2, 3}, {3, 3}}},
    {"L", {{1, 2}, {2, 2}, {3, 2}, {1, 3}}},
    {"T", {{1, 2}, {2, 2}, {3, 2}, {2, 3}}}
}

local Board

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
    log("Board", Board)
    -- Board[5][5] = 1
    -- Board[6][6] = 1
    Level = 1
    CPX = 5
    CPY = 0
    setCurrentPiece(Pieces[4])
end

function setCurrentPiece(piece)
    CurrentPiece = {
        {0, 0, 0, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0},
        {0, 0, 0, 0}
    }

    for _, p in ipairs(piece[2]) do
        local x, y = unpack(p)
        CurrentPiece[x][y] = 1
    end

    return CurrentPiece
end

function love.load()
    GameState = "TITLE_SCREEN"
    initGameState()
    log(setCurrentPiece(Pieces[3]))
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
                local x_ = CPX - 1 + x_
                local y_ = CPY - 1 + y_
                if x_ < 1 or x_ > BoardWidth or y_ < 1 or y > BoardHeight or Board[x_][y_] > 0 then
                    return false
                end
            end
        end
    end
    return true
end

function drawBoard(x, y, s)
    for row = 1 + HiddenRows, BoardHeight do
        for col = 1, BoardWidth do
            local block = Board[col][row]
            local x_ = x + s * (col - 1)
            local y_ = y + s * (row - HiddenRows - 1)
            if block > 0 then
                love.graphics.setColor(1, 1, .8, 1)
                love.graphics.setLineWidth(3)
            else
                love.graphics.setColor(0.8, 0.8, 0.8, 0.25)
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
            local x_ = x + s * gx
            local y_ = y + s * (gy - HiddenRows - 1)
            if gx > 0 and gx <= BoardWidth and gy >= HiddenRows and gy <= BoardHeight and CurrentPiece[cx][cy] > 0 then
                -- log(gy, HiddenRows)
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
        love.graphics.print("In game", 20, 20)
        love.graphics.print("Level " .. Level, 20, 50)
        for i = 1, #Pieces do
            drawPiece(Pieces[i], 100, 100 * i - 100)
        end
        drawBoard(400, 0, 18)
    end
end

local t = 0
function love.update(dt)
    t = t + dt
    CPY = math.floor(t * 1.3) + 1
end

function drawPiece(p, x, y)
    -- local color = p[1]
    local color = {0.8, 0.8, 0.8, 1.0}
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
    drawCurrentPiece()
end

function drawCurrentPiece()
    local size = 20
    love.graphics.setColor(0.3, 0.8, 0.3, 1.0)
    love.graphics.setLineWidth(3)
    for x = 1, 4 do
        for y = 1, 4 do
            if CurrentPiece[x][y] > 0 then
                love.graphics.rectangle("line", 300 + x * size, 100 + y * size, size, size)
            end
        end
    end
end

function love.keypressed(key, scancode, isrepeat)
    if GameState == "TITLE_SCREEN" then
        GameState = "IN_GAME"
    elseif GameState == "IN_GAME" then
        Level = Level + 1
        if key == "r" then
            rotateCurrentPieceRight()
        elseif key == "l" then
            rotateCurrentPieceLeft()
        elseif key == "p" then
            setCurrentPiece(Pieces[love.math.random(1, 5)])
        end
        log("Key pressed in game")
    end
end
