local R={}
function R.state()return ModData.getOrCreate('TSBAstroluxStructure.Lab.v1')end
function R.all()
    local db=R.state();local out,seen={},{}
    if db.tower then out[#out+1]=db.tower;seen[db.tower.id or db.tower]=true end
    for _,r in pairs(db.showrooms or {})do if not seen[r.id or r] then out[#out+1]=r;seen[r.id or r]=true end end
    return out
end
function R.near(x,y)
    local best,score
    for _,r in ipairs(R.all())do
        local dx=math.max(r.x-x,0,x-r.x-8);local dy=math.max(r.y-y,0,y-r.y-8)
        local distance=dx*dx+dy*dy+((x-r.x-4)^2+(y-r.y-4)^2)*0.00001
        if not score or distance<score then best=r;score=distance end
    end
    return best
end
return R
