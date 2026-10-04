check('false reaches inherited instance property setter unchanged',function()
 local Parent=Classic:extend('FlagParent')
 function Parent:set_enabled(value) self.received=value end
 local Child=Parent:extend('FlagChild');local instance=Child()
 instance.enabled=true;assert(instance.received==true)
 instance.enabled=false;assert(instance.received==false,'false value converted to nil')
 instance.enabled=nil;assert(instance.received==nil)
end)
check('class-level property setter keeps its single value argument',function()
 local C=Classic:extend('StaticFlag');local result
 C.set_enabled=function(value) result=value end
 C.enabled=false;assert(result==false)
end)
