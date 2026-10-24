local F={border='floors_interior_tilesandwood_01_29',inner='floors_interior_tilesandwood_01_28'}
function F.plan(x,y)
    local tiles={}
    for dx=0,10 do for dy=0,10 do
        local edge=dx==0 or dx==10 or dy==0 or dy==10
        tiles[#tiles+1]={x=x+dx,y=y+dy,sprite=edge and F.border or F.inner}
    end end
    return tiles
end
return F
