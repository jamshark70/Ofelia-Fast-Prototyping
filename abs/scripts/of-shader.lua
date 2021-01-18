local canvas = ofCanvas(this);
local shaderDir = canvas:getDir() .. "/";
local outlet = ofOutlet(this);
local pix = ofPixels();
M.shader = ofShader();
M.image = ofFbo();
M.useShader = 1;
M.useFbo = 1;
ofDisableArbTex();
;
-- initialize;
function M.new();
local dir = ofCanvas(this):getDir();
local params = ofTable();
local args = canvas:getArgs();
local path = dir .. "/shaders/" .. args[1];
print("path", path);
if file_exists(path .. ".desc") then;
for line in io.lines(path .. ".desc") do;
print(line);
local entry = M.parseLine(line);
for k, v in pairs(entry) do print(k, v) end;
params[entry['name']] = entry;
M[entry['name'] .. "List"] = entry['default'];
M.setParams[entry['type']](entry['name'], entry['default']);
end;
M.paramTable = params;
M.shader:load(path);
else error("Undefined shader " .. args[1]) end;
end;
function M.useShader(f) useShader = f end;
function M.setImageID(sym) M.id = sym end;
;
-- drawing related: get source and draw;
function M.imageID(sym);
M.sourceId = sym;
M.imageSource = require(sym);
local img = M.imageSource.image;
if(img:getWidth() ~= M.image:getWidth() or img:getHeight() ~= M.image:getHeight()) then;
M.image:clear();
M.image:allocate(img:getWidth(), img:getHeight(), GL_RGBA);
print("allocated for image ID", sym);
print("w =", M.image:getWidth(), ", h =", M.image:getHeight());
end;
end;
function M.bang();
M.image:beginFbo();
ofClear(128, 255);
M.shader:beginShader();
for name, entry in pairs(M.paramTable) do;
M.sendParams[ M.sendFuncsByType[ entry['type'] ] ] (name, M[name]);
end;
M.shader:setUniform2f("dimen", ofVec2f(M.imageSource.image:getWidth(), M.imageSource.image:getHeight()):vec2());
M.imageSource.image:draw(0, 0);
M.shader:endShader();
M.image:endFbo();
if(M.useFbo ~= 0) then outlet:outletList(0, ofTable("imageID", M.id)) else outlet:outletList(0, ofTable("imageID", M.imageSourceId)) end;
outlet:outletBang(0);
end;
function M.free() M.shader:unload() M.image:clear() end;
;
-- functions to send parameters to the shader;
M.sendParams = {
send1f = function(param, f) M.shader:setUniform1f(param, f) end,
send2f = function(param, vec) M.shader:setUniform2f(param, vec) end,
send3f = function(param, vec) M.shader:setUniform3f(param, vec) end,
send4f = function(param, color) M.shader:setUniform4f(param, color) end
};
M.sendFuncsByType = {
oneF = 'send1f', twoF = 'send2f', threeF = 'send3f',
grey = 'send4f', greyA = 'send4f', rgb = 'send4f', rgba = 'send4f',
greyF = 'send4f', greyAF = 'send4f', rgbF = 'send4f', rgbaF = 'send4f'
};
-- convert data types into sendable objects;
M.setParams = {
oneF = function(param, f) M[param] = f end,
twoF = function(param, v) M[param] = ofVec2f(v[1], v[2]) end,
threeF = function(param, v) M[param] = ofVec3f(v[1], v[2], v[3]) end,
grey = function(param, g) M[param] = ofColor(g[1], g[1], g[1], 1) end,
greyA = function(param, g) M[param] = ofColor(g[1], g[1], g[1], g[1]) end,
rgb = function(param, v) M[param] = ofColor(v[1], v[2], v[3], 1) end,
rgba = function(param, v) M[param] = ofColor(v[1], v[2], v[3], v[4]) end,
greyF = function(param, g) M[param] = ofFloatColor(g[1], g[1], g[1], 1) end,
greyAF = function(param, g) M[param] = ofFloatColor(g[1], g[1], g[1], g[1]) end,
rgbF = function(param, v) M[param] = ofFloatColor(v[1], v[2], v[3], 1) end,
rgbaF = function(param, v) M[param] = ofFloatColor(v[1], v[2], v[3], v[4]) end
};
-- allow colors to be set as either grey or rgb;
M.convertFuncs = { rgb = {}, rgba = {}, rgbF = {}, rgbaF = {} };
M.convertFuncs['rgb'][1] = function(v) return ofTable(v[1], v[1], v[1]) end;
M.convertFuncs['rgba'][1] = function(v) return ofTable(v[1], v[1], v[1], v[1]) end;
M.convertFuncs['rgbF'][1] = function(v) return ofTable(v[1], v[1], v[1]) end;
M.convertFuncs['rgbaF'][1] = function(v) return ofTable(v[1], v[1], v[1], v[1]) end;
M.convertFuncs['rgba'][3] = function(v) return ofTable(v[1], v[1], v[1], M.luma(v)) end;
M.convertFuncs['rgbaF'][3] = function(v) return ofTable(v[1], v[1], v[1], M.luma(v)) end;
function M.luma(v) return 0.2126*v[1] + 0.7152*v[2] + 0.0722*v[3] end;
-- parameter setter/getter;
function M.setParameter(list);
local name = list[1];
local descriptor = M.paramTable[name];
if descriptor ~= nil then
local values = M.subList(list, 2, #list);
local convertTable = M.convertFuncs[descriptor['type']];
if convertTable ~= nil then
local convert = convertTable[#values];
if convert ~= nil then values = convert(values);
end end;
-- if the input list format is wrong, this will fail;
-- protecting the "List" storage;
M.setParams[descriptor['type']](name, values);
M[name .. "List"] = values;
else error("Undefined parameter " .. name) end;
end;
function M.getParameter(name) return(M[name .. "List"]) end;
function M.subList(list, startIndex, endIndex);
local newlist = ofTable();
for i = startIndex, endIndex, 1 do newlist[#newlist + 1] = list[i] end;
return(newlist);
end;
;
-- support functions;
function M.printModule() -- debugging only, remove later;
for k, v in pairs(M) do print(k, v) end;
end;
function M.parseLine(line);
local entry = ofTable();
local default = ofTable();
local i = 0;
for token in string.gmatch(line, "[^%s]+") do;
if i == 0 then entry['name'] = token;
else if i == 1 then entry['type'] = token;
else default[#default + 1] = tonumber(token);
end end;
i = i + 1;
end;
entry['default'] = default;
return entry;
end;
function file_exists(file);
print("testing path", file);
local f = io.open(file, "rb");
if f then f:close() end;
return f ~= nil;
end;