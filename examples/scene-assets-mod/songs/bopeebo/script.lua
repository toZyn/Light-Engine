function postCreate()
 local decoration=Mod.sprite('sceneDecoration','stages/stage/stage_light',30,100,{scale=.2,camera='hud'})
 state:add(decoration)
 Mod.sceneTrack('intro-decoration',decoration)
end
