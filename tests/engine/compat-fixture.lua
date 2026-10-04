function onTweenCompleted(tag) tweenTag=tag end
function onTimerCompleted(tag,loops,left) timerTag=tag; timerCount=loops; timerLeft=left end
function onCreate() created=true end
function onCreatePost() postCreated=true end
function onEvent(name,v1,v2) eventName=name; assert(v1=='yes' and v2=='no') end
function onUpdatePost(dt) postDt=dt end
function native(value) nativeValue=value end
