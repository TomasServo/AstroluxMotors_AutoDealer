local F={border='floors_interior_tilesandwood_01_29',inner='floors_interior_tilesandwood_01_11'}
function F.plan(x,y)
    local tiles={}
    for dx=0,11 do for dy=0,11 do
        local edge=dx==0 or dx==11 or dy==0 or dy==11
        tiles[#tiles+1]={x=x+dx,y=y+dy,sprite=edge and F.border or F.inner}
    end end
    return tiles
end
return F
