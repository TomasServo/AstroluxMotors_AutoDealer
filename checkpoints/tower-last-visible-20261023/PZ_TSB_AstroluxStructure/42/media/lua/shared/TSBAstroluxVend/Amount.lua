-- No configured price ceiling. Reject invalid or inexact currency values.
local A={}
function A.valid(n,min)
    return type(n)=='number' and n==n and n<math.huge and n>=min
        and n==math.floor(n) and n+1.0>n
end
function A.check(n,min)
    if not A.valid(n,min or 0)then error('Enter a finite, exactly representable whole-dollar amount.',0)end
    return n
end
function A.add(a,b)
    A.check(a,0);A.check(b,0)
    local total=A.check(a+0.0+b,0)
    if total-a~=b or total-b~=a then error('Whole-dollar total cannot be represented exactly.',0)end
    return total
end
return A
