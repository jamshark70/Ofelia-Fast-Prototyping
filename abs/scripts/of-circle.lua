local c = ofCanvas(this);
local args = c:getArgs();
M.node = ofNode();
local size, res, drawmode, strokeweight, debug = args[1], args[2], args[3], args[4];
local position, orientation, scale, lookat = ofVec3f(), ofVec3f(), ofVec3f(1, 1, 1), ofVec3f();
;
function M.new();
if args[1] == nil then size = 50 end;
if args[2] == nil then res = 20 end;
if args[3] == nil then drawmode = "fill" end;
if args[4] == nil then strokeweight = 1 end;
end;
;
function M.size(f) size=f end;
function M.res(f) res=f end;
function M.draw(s) drawmode = s end;
function M.stroke(f) strokeweight = f end;
function M.list(l) width = l[1] height = l[2] drawmode = l[3] strokeweight = l[4] end;
function M.debug(f) debug = f end;
function M.position(l) position:set (l[1], l[2], l[3]) M.node:setPosition(position:vec3()) end;
function M.orientation(l) orientation:set (l[1], l[2], l[3]) M.node:setOrientation(orientation:vec3()) end;
function M.scale(l) scale:set (l[1], l[2], l[3]) M.node:setScale(scale:vec3()) end;
function M.lookat(l) lookat.x=l[1] lookat.y=l[2] lookat.z=l[3] M.node:lookAt(lookat:vec3()) end;
function M.imageID(sym);
if sym == nil then M.imageSource = nil M.lastID = nil return("imageID");
else if sym ~= lastID then;
M.imageSource = require(sym);
M.lastID = sym;
return ofTable("imageID", sym);
end;
end;
end;
;
function M.bang();
ofSetLineWidth(strokeweight);
if M.imageSource ~= nil then M.imageSource.image:getTexture():bind() end;
if drawmode == "line" then ofNoFill() end;
M.node:transformGL();
ofSetCircleResolution(math.abs(res));
ofDrawCircle(0, 0, 0, size);
M.node:restoreTransformGL();
if debug == 1 then M.node:draw() end;
ofFill();
if M.imageSource ~= nil then M.imageSource.image:getTexture():unbind() end;
return anything;
end;
